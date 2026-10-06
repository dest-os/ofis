import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../application/runtime/paid_ai_runtime_gate.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import '../../domain/runtime/ai_runtime_request.dart';
import '../codegen/code_validator_service.dart';
import '../codegen/code_writer_service.dart';
import '../video/ffmpeg_command_builder.dart';

/// Video ve genel içerik üretimini ortak güvenlik ve kalite kapısından geçirir.
class ContentGenerationOrchestrator {
  /// Creates a content orchestrator with an ARES AI gateway and secure writer.
  const ContentGenerationOrchestrator({
    required AresAiGateway gateway,
    required CodeWriterService writer,
    CodeValidatorService validator = const CodeValidatorService(),
    PaidAiRuntimeGate paidGate = const PaidAiRuntimeGate(),
    this.costClass = AiCostClass.local,
    this.outputPrefix = 'ARES_Output',
  })  : _gateway = gateway,
        _writer = writer,
        _validator = validator,
        _paidGate = paidGate;

  final AresAiGateway _gateway;
  final CodeWriterService _writer;
  final CodeValidatorService _validator;
  final PaidAiRuntimeGate _paidGate;

  /// AI maliyet sınıfı.
  final AiCostClass costClass;

  /// Separate output root under the application documents directory.
  final String outputPrefix;

  /// Generates a video or general-content package from a high-level request.
  Future<ContentGenerationResult> generate({
    required ContentMode mode,
    required String request,
    String duration = '60 saniye',
    String style = 'modern, temiz ve ARES uyumlu',
    String platform = 'YouTube Shorts',
    String contentType = 'uygulama fikri dokümanı',
    void Function(String status)? onProgress,
  }) async {
    final text = request.trim();
    if (text.length < 8) {
      return ContentGenerationResult(
        success: false,
        artifacts: <CodeArtifact>[],
        errors: <String>['İstek çok kısa. Üretilecek içeriğin amacını açıkça yazın.'],
        suggestedActions: <String>['En az birkaç kelimelik somut bir fikir girin.'],
        metrics: <String, Object?>{},
      );
    }
    onProgress?.call('İstek: içerik üretim talebi hazırlanıyor.');
    final instruction = _buildInstruction(mode, text, duration, style, platform, contentType);
    final gate = _paidGate.evaluate(AiRuntimeRequest(
      instruction: instruction,
      costClass: costClass,
      metadata: <String, Object?>{'feature': 'content_generation', 'mode': mode.name},
    ));
    if (!gate.mayRun) {
      return ContentGenerationResult(
        success: false,
        artifacts: const <CodeArtifact>[],
        errors: <String>[gate.reason],
        suggestedActions: const <String>[
          'Yerel AI veya doğrulanmış ücretsiz AI yapılandırın.',
          'Ücretli AI kullanacaksanız açık kullanıcı onayı gereklidir.',
        ],
        metrics: <String, Object?>{'costClass': costClass.name},
      );
    }
    onProgress?.call('Product Manager: fikir ve kabul kriterleri netleştiriliyor.');
    final pm = await _agentCall('ProductManager', '''İstek: $text\nMod: ${mode.name}\nSüre: $duration\nStil: $style\nPlatform: $platform\nİçerik türü: $contentType\nSadece brief.md artifact'i üret ve kabul kriterlerini yaz.''');
    if (pm is AresFailure<List<CodeArtifact>>) return _failure(pm.message);

    onProgress?.call('Architect: içerik üretim planı hazırlanıyor.');
    final architect = await _agentCall('Architect', '''İstek: $text\nMod: ${mode.name}\nİçerik türü: $contentType\nProduct Manager çıktısı: ${_artifactText((pm as AresSuccess<List<CodeArtifact>>).value)}\nSadece architecture.md artifact'i üret; üretim adımlarını ve dosya sözleşmesini tanımla.''');
    if (architect is AresFailure<List<CodeArtifact>>) return _failure(architect.message);

    onProgress?.call('Specialist Producer: içerik paketi üretiliyor.');
    final specialist = await _agentCall('SpecialistProducer', _buildInstruction(mode, text, duration, style, platform, contentType) + '\nProduct Manager: ${_artifactText((pm as AresSuccess<List<CodeArtifact>>).value)}\nArchitect: ${_artifactText((architect as AresSuccess<List<CodeArtifact>>).value)}');
    if (specialist is AresFailure<List<CodeArtifact>>) return _failure(specialist.message);
    final specialistArtifacts = (specialist as AresSuccess<List<CodeArtifact>>).value;

    onProgress?.call('QA Engineer: çıktı sözleşmesi kontrol ediliyor.');
    final qa = await _agentCall('QAEngineer', '''İstek: $text\nMod: ${mode.name}\nÜretilen yollar: ${specialistArtifacts.map((a) => a.relativePath).join(', ')}\nKısa kalite kontrol raporu üret ve quality_checklist.md artifact'i döndür.''');
    if (qa is AresFailure<List<CodeArtifact>>) return _failure(qa.message);

    onProgress?.call('DevOps / Release: üretim ve yayın kontrolü hazırlanıyor.');
    final devops = await _agentCall('DevOps', '''İstek: $text\nMod: ${mode.name}\nPlatform: $platform\nÜretilen yollar: ${specialistArtifacts.map((a) => a.relativePath).join(', ')}\nGüvenli üretim/yayın kontrolü hazırla. Video ise production_checklist.md; diğer içerikte release_checklist.md üret.''');
    if (devops is AresFailure<List<CodeArtifact>>) return _failure(devops.message);

    final artifacts = <CodeArtifact>[
      ...((pm as AresSuccess<List<CodeArtifact>>).value),
      ...((architect as AresSuccess<List<CodeArtifact>>).value),
      ...specialistArtifacts,
      ...((qa as AresSuccess<List<CodeArtifact>>).value),
      ...((devops as AresSuccess<List<CodeArtifact>>).value),
    ];

    if (mode == ContentMode.video) {
      _appendVideoPipelineArtifacts(artifacts, duration: duration, platform: platform);
    }

    final contractErrors = _contractErrors(mode, contentType, artifacts);
    if (contractErrors.isNotEmpty) {
      return ContentGenerationResult(
        success: false, artifacts: artifacts, errors: contractErrors,
        suggestedActions: const <String>['Ajanlardan biri zorunlu dosya sözleşmesini tamamlamadı; üretimi tekrar deneyin.'],
        metrics: <String, Object?>{'costClass': costClass.name},
      );
    }

    final validation = _validator.validate(artifacts);
    if (!validation.isValid) {
      return ContentGenerationResult(
        success: false,
        artifacts: artifacts,
        errors: validation.errors,
        suggestedActions: validation.suggestedActions,
        metrics: <String, Object?>{},
      );
    }
    onProgress?.call('Yazma: içerik paketi güvenli çıktı köküne yazılıyor.');
    final requestSafe = _safeRequestFolder(text);
    final writeArtifacts = artifacts.map((artifact) => artifact.copyWith(relativePath: '$outputPrefix/${mode.name}/$requestSafe/${artifact.relativePath}')).toList(growable: false);
    final writeResult = await _writer.writeArtifacts(writeArtifacts, overwrite: false);
    if (!writeResult.success) {
      return ContentGenerationResult(
        success: false,
        artifacts: artifacts,
        errors: writeResult.errors,
        suggestedActions: const <String>['Çıktı klasörünün yazılabilir olduğunu kontrol edin.'],
        metrics: <String, Object?>{'written': writeResult.writtenPaths.length},
      );
    }
    onProgress?.call('Tamam: içerik paketi hazır.');
    return ContentGenerationResult(
      success: true,
      artifacts: artifacts,
      errors: const <String>[],
      suggestedActions: const <String>[],
      metrics: <String, Object?>{
        'written': writeResult.writtenPaths.length,
        'costClass': costClass.name,
        'outputRoot': '$outputPrefix/${mode.name}/$requestSafe',
        if (mode == ContentMode.video) 'renderArguments': const FfmpegCommandBuilder().buildMp4Command(outputFileName: 'render.mp4', durationSeconds: _parseDurationSeconds(duration), videoInput: 'assets/video_source.mp4'),
      },
    );
  }

  String _safeRequestFolder(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'uretim' : normalized.substring(0, normalized.length > 60 ? 60 : normalized.length);
  }

  Future<AresResult<List<CodeArtifact>>> _agentCall(String role, String instruction) async {
    final result = await _gateway.generate(AiRequest(instruction: '''Sen DEST-OS ARES $role ajanısın. Çıktı yalnızca geçerli JSON olsun: {"artifacts":[{"relativePath":"...","content":"...","type":"markdown|other","generatedBy":"$role"}]}. Path göreli olmalı ve ARES kaynak kodunu değiştirmemeli.\n$instruction''', costClass: costClass));
    if (result is AresFailure<AiResponse>) return AresFailure<List<CodeArtifact>>(result.message);
    try {
      return _parseArtifacts((result as AresSuccess<AiResponse>).value.text);
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('Ajan $role çıktısı çözülemedi: $error');
    }
  }

  ContentGenerationResult _failure(String message) => ContentGenerationResult(
        success: false, artifacts: const <CodeArtifact>[], errors: <String>[message],
        suggestedActions: const <String>['Local AI modelini, endpoint adresini ve JSON çıktı sözleşmesini kontrol edin.'],
        metrics: <String, Object?>{'costClass': costClass.name},
      );

  String _artifactText(List<CodeArtifact> artifacts) => artifacts.map((a) => '${a.relativePath}:\n${a.content}').join('\n');

  String _buildInstruction(ContentMode mode, String request, String duration, String style, String platform, String contentType) {
    final required = _specialistPaths(mode, contentType);
    final contract = mode == ContentMode.video
        ? 'Specialist Producer zorunlu yolları: ${required.join(', ')}. DevOps production_checklist.md, QA quality_checklist.md üretir.'
        : 'Specialist Producer zorunlu yolları: ${required.join(', ')}. Product Manager brief.md, Architect architecture.md, QA quality_checklist.md, DevOps release_checklist.md üretir.';
    return '''Sen DEST-OS ARES Specialist Producer ajanısın.
İstek: $request
Mod: ${mode.name}
Süre: $duration
Stil: $style
Platform: $platform
$contract
Çıktı SADECE geçerli JSON olmalı: {"artifacts":[{"relativePath":"...","content":"...","type":"markdown|other","generatedBy":"SpecialistProducer"}]}
Path yalnızca göreli olmalı. ARES kaynak kodunu değiştirme. Video captions.srt gerçek SRT zaman damgaları içermeli. Sahte render yapılmış gibi yazma.''';
  }

  AresResult<List<CodeArtifact>> _parseArtifacts(String raw) {
    try {
      dynamic decoded = jsonDecode(raw);
      if (decoded is Map) decoded = decoded['artifacts'];
      if (decoded is! List) return const AresFailure<List<CodeArtifact>>('İçerik AI çıktısında artifacts listesi yok.');
      final result = <CodeArtifact>[];
      for (final item in decoded) {
        if (item is! Map || item['relativePath'] is! String || item['content'] is! String) {
          return const AresFailure<List<CodeArtifact>>('İçerik AI çıktısında geçersiz artifact bulundu.');
        }
        final path = item['relativePath'] as String;
        if (_unsafe(path)) return AresFailure<List<CodeArtifact>>('Güvenli olmayan çıktı yolu reddedildi: $path');
        result.add(CodeArtifact(
          relativePath: path,
          content: item['content'] as String,
          type: item['type'] == 'other' ? ArtifactType.other : ArtifactType.markdown,
          generatedBy: item['generatedBy'] is String && (item['generatedBy'] as String).trim().isNotEmpty ? item['generatedBy'] as String : 'SpecialistProducer',
        ));
      }
      return AresSuccess<List<CodeArtifact>>(List.unmodifiable(result));
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('İçerik AI JSON çıktısı bozuk: $error');
    }
  }

  List<String> _contractErrors(ContentMode mode, String contentType, List<CodeArtifact> artifacts) {
    final paths = artifacts.map((a) => a.relativePath).toSet();
    final required = _requiredPaths(mode, contentType);
    final errors = required.where((path) => !paths.contains(path)).map((path) => 'Zorunlu çıktı eksik: $path').toList();
    if (mode == ContentMode.video) {
      final srt = _contentOf(artifacts, 'captions.srt');
      if (!RegExp(r'(?m)^\d+\s*\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}').hasMatch(srt)) {
        errors.add('captions.srt geçerli SRT zaman damgası içermiyor.');
      }
      final checklist = _contentOf(artifacts, 'production_checklist.md');
      if (!checklist.toLowerCase().contains('ffmpeg')) {
        errors.add('production_checklist.md ffmpeg render planı içermiyor.');
      }
    }
    return errors;
  }

  void _appendVideoPipelineArtifacts(
    List<CodeArtifact> artifacts, {
    required String duration,
    required String platform,
  }) {
    final seconds = _parseDurationSeconds(duration);
    final script = _contentOf(artifacts, 'script.md');
    final sceneMatches = RegExp(r'(?im)^#{1,3}\s*(?:sahne|scene)\s*[^\n]*')
        .allMatches(script)
        .length;
    final sceneCount = sceneMatches == 0 ? 1 : sceneMatches.clamp(1, 60).toInt();
    final segment = seconds / sceneCount;
    final timeline = <Map<String, Object>>[];
    for (var i = 0; i < sceneCount; i++) {
      timeline.add(<String, Object>{
        'scene': i + 1,
        'startSeconds': (i * segment).round(),
        'endSeconds': ((i + 1) * segment).round(),
      });
    }
    final renderArgs = const FfmpegCommandBuilder().buildMp4Command(
      outputFileName: 'render.mp4',
      durationSeconds: seconds,
      videoInput: 'assets/video_source.mp4',
    );
    final renderJson = JsonEncoder.withIndent('  ').convert(<String, Object>{
      'executable': 'ffmpeg',
      'arguments': renderArgs,
      'automaticExecution': false,
      'output': 'render.mp4',
      'outputRoot': 'ARES_Output/video/<slug>',
    });
    final finalTimelineJson = JsonEncoder.withIndent('  ').convert(<String, Object>{
      'durationSeconds': seconds,
      'platform': platform,
      'scenes': timeline,
    });
    artifacts.removeWhere((artifact) => <String>{'assets_plan.md', 'timeline.json', 'render_plan.json'}.contains(artifact.relativePath));
    artifacts.addAll(<CodeArtifact>[
      CodeArtifact(
        relativePath: 'assets_plan.md',
        content: '# Assets Plan\n\n- Görsel varlıklar: shot_list.md içindeki her sahne için belirtilen görseller.\n- Ses: voiceover_script.md ve gerektiğinde lisanslı müzik.\n- Kaynaklar kullanıcı tarafından sağlanmalı veya lisansı doğrulanmalıdır.\n- Otomatik indirme yapılmaz.\n',
        type: ArtifactType.markdown,
        generatedBy: 'Architect',
      ),
      CodeArtifact(relativePath: 'timeline.json', content: finalTimelineJson, type: ArtifactType.json, generatedBy: 'Architect'),
      CodeArtifact(relativePath: 'render_plan.json', content: renderJson, type: ArtifactType.json, generatedBy: 'DevOps'),
    ]);
  }

  int _parseDurationSeconds(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    final parsed = int.tryParse(match?.group(1) ?? '') ?? 60;
    return parsed.clamp(1, 86400).toInt();
  }

  List<String> _specialistPaths(ContentMode mode, String contentType) {
    if (mode == ContentMode.video) {
      return const <String>['video_brief.md', 'script.md', 'shot_list.md', 'voiceover_script.md', 'captions.srt', 'thumbnail_prompt.md'];
    }
    switch (contentType) {
      case 'Pazarlama Metni':
        return const <String>['marketing_copy.md', 'variants.md'];
      case 'Post Serisi':
        return const <String>['posts.md', 'captions.md', 'hashtag_plan.md'];
      case 'Ürün Açıklaması':
        return const <String>['product_description.md', 'feature_bullets.md', 'seo_keywords.md'];
      default:
        return const <String>['content.md', 'acceptance_criteria.md'];
    }
  }

  List<String> _requiredPaths(ContentMode mode, String contentType) {
    if (mode == ContentMode.video) {
      return const <String>[
        'video_brief.md', 'script.md', 'shot_list.md', 'voiceover_script.md',
        'captions.srt', 'thumbnail_prompt.md', 'assets_plan.md', 'timeline.json', 'render_plan.json', 'production_checklist.md', 'quality_checklist.md',
      ];
    }
    switch (contentType) {
      case 'Pazarlama Metni':
        return const <String>['brief.md', 'marketing_copy.md', 'variants.md', 'quality_checklist.md', 'release_checklist.md'];
      case 'Post Serisi':
        return const <String>['brief.md', 'posts.md', 'captions.md', 'hashtag_plan.md', 'quality_checklist.md', 'release_checklist.md'];
      case 'Ürün Açıklaması':
        return const <String>['brief.md', 'product_description.md', 'feature_bullets.md', 'seo_keywords.md', 'quality_checklist.md', 'release_checklist.md'];
      default:
        return const <String>['brief.md', 'content.md', 'architecture.md', 'acceptance_criteria.md', 'quality_checklist.md', 'release_checklist.md'];
    }
  }

  String _contentOf(List<CodeArtifact> artifacts, String path) {
    for (final artifact in artifacts) {
      if (artifact.relativePath == path) return artifact.content;
    }
    return '';
  }

  bool _unsafe(String path) {
    final value = path.trim().replaceAll('\\', '/');
    return value.isEmpty || value.startsWith('/') || value == '..' || value.contains('../');
  }
}
