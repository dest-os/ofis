import '../../application/events/event_bus.dart';
import '../ceo/ceo_self_heal_service.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/codegen/generation_plan.dart';
import '../../domain/codegen/generation_result.dart';
import '../../domain/codegen/project_spec.dart';
import '../../domain/events/event_envelope.dart';
import '../../domain/events/event_type.dart';
import '../../infrastructure/codegen/llm_code_generator.dart';
import 'build_readiness_service.dart';
import 'code_validator_service.dart';
import 'code_writer_service.dart';
import 'project_scaffold_service.dart';
import 'prompt_builder_service.dart';

/// Kod Üretim Motorunun ana uygulama orkestratörüdür.
///
/// [ProjectSpec] girdisini üretim planına dönüştürür; iskelet, domain,
/// application ve presentation artifact'lerini üretir; doğrulama ve en fazla
/// üç self-healing turu uygular; ardından dosyaları güvenli writer katmanına
/// teslim eder ve son doğrulamayı yapar. LLM çağrıları yalnızca verilen
/// [LlmCodeGenerator] üzerinden yapılır; bu sınıf ücretli AI güvenlik kapısını
/// bypass etmez.
class CodeGenerationOrchestrator {
  /// Creates a code-generation orchestrator from configured services.
  CodeGenerationOrchestrator({
    required ProjectScaffoldService scaffoldService,
    required PromptBuilderService promptBuilder,
    required LlmCodeGenerator llmCodeGenerator,
    required CodeWriterService codeWriter,
    required CodeValidatorService validator,
    this.eventBus,
    this.logger,
    this.aiCostClass = AiCostClass.unknown,
    this.buildReadinessService = const BuildReadinessService(),
    this.provider,
    this.model,
    CeoSelfHealService? ceoSelfHealService,
  })  : _scaffoldService = scaffoldService,
        _promptBuilder = promptBuilder,
        _llmCodeGenerator = llmCodeGenerator,
        _codeWriter = codeWriter,
        _validator = validator,
        ceoSelfHealService = ceoSelfHealService ?? CeoSelfHealService(
          llmCodeGenerator: llmCodeGenerator,
          costClass: aiCostClass,
          provider: provider,
          model: model,
        );

  final ProjectScaffoldService _scaffoldService;
  final PromptBuilderService _promptBuilder;
  final LlmCodeGenerator _llmCodeGenerator;
  final CodeWriterService _codeWriter;
  final CodeValidatorService _validator;

  /// CEO self-heal servisi; mevcut AI maliyet güvenlik politikasını kullanır.
  final CeoSelfHealService ceoSelfHealService;

  /// Deterministic build-readiness checker used before the final write.
  final BuildReadinessService buildReadinessService;

  /// Optional Event Bus used for lifecycle notifications.
  final EventBus? eventBus;

  /// Optional diagnostic logger.
  final void Function(String message)? logger;

  /// Cost classification required for every LLM call. Unknown is the safe default.
  final AiCostClass aiCostClass;

  /// Optional provider identifier passed to the configured LLM gateway.
  final String? provider;

  /// Optional model identifier passed to the configured LLM gateway.
  final String? model;

  /// Maximum number of retries after the first LLM attempt for a phase.
  static const int maxRetriesPerStep = 3;

  /// Maximum number of validation repair attempts.
  static const int maxSelfHealingAttempts = 3;

  /// Generates, validates, repairs when necessary, and safely writes a project.
  ///
  /// [onProgress] receives short Turkish status messages so the presentation
  /// layer can show live progress without knowing anything about the engine's
  /// internal services.
  Future<GenerationResult> generate(
    ProjectSpec spec, {
    void Function(String status)? onProgress,
  }) async {
    final startedAt = DateTime.now();
    final logs = <String>[];
    final errors = <String>[];
    final suggestions = <String>[];
    final artifacts = <CodeArtifact>[];
    var retryCount = 0;
    var selfHealingCount = 0;
    final ceoNotes = <String>[];

    Future<void> log(String message) async {
      final entry = '[${DateTime.now().toIso8601String()}] $message';
      logs.add(entry);
      logger?.call(entry);
      onProgress?.call(message);
    }

    await log('İstek: Kod üretimi başlatıldı.');
    await _publish(
      type: EventType.systemStarted,
      message: 'code_generation_started',
      projectName: spec.projectName,
    );

    final plan = _createPlan(spec);
    await log('Plan: System Architect ajanı için ${plan.steps.length} üretim adımı hazır.');

    List<CodeArtifact> scaffold;
    try {
      await log('Scaffold: Flutter proje iskeleti oluşturuluyor.');
      scaffold = _scaffoldService.generate(spec);
    } catch (error) {
      final message = 'Proje iskeleti üretilemedi: $error';
      errors.add(message);
      await log('Hata: $message');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    artifacts.addAll(scaffold);
    await log('Scaffold: ${scaffold.length} artifact oluşturuldu.');

    await log('Doğrulama: proje iskeleti kontrol ediliyor.');
    final scaffoldValidation = _validator.validate(scaffold);
    if (!scaffoldValidation.isValid) {
      errors.addAll(scaffoldValidation.errors);
      suggestions.addAll(scaffoldValidation.suggestedActions);
      await log('Hata: proje iskeleti doğrulaması başarısız.');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    const phases = <_GenerationPhase>[
      _GenerationPhase(
        name: 'Product Manager',
        role: CodegenAgentRole.productManager,
        directory: 'docs/product/',
      ),
      _GenerationPhase(
        name: 'System Architect',
        role: CodegenAgentRole.architect,
        directory: 'docs/architecture/',
      ),
      _GenerationPhase(
        name: 'Domain',
        role: CodegenAgentRole.flutterDeveloper,
        directory: 'lib/domain/',
      ),
      _GenerationPhase(
        name: 'Application',
        role: CodegenAgentRole.flutterDeveloper,
        directory: 'lib/application/',
      ),
      _GenerationPhase(
        name: 'Presentation',
        role: CodegenAgentRole.flutterDeveloper,
        directory: 'lib/presentation/',
      ),
      _GenerationPhase(
        name: 'QA Engineer',
        role: CodegenAgentRole.qaEngineer,
        directory: 'test/generated/',
      ),
      _GenerationPhase(
        name: 'DevOps / Release',
        role: CodegenAgentRole.devOps,
        directory: 'docs/release/',
      ),
    ];

    for (final phase in phases) {
      await log('${phase.name}: üretim başladı.');
      final phaseResult = await _runPhaseWithRetry(
        phase: phase,
        spec: spec,
        existingArtifacts: artifacts,
        onLog: log,
      );
      retryCount += phaseResult.retries;

      final result = phaseResult.result;
      if (result is AresFailure<List<CodeArtifact>>) {
        final message = '${phase.name}: ${result.message}';
        errors.add(message);
        suggestions.addAll(_aiSetupSuggestions());
        await log('Hata: $message');
        return _result(
          success: false,
          artifacts: artifacts,
          errors: errors,
          suggestions: suggestions,
          logs: logs,
          retryCount: retryCount,
          selfHealingCount: selfHealingCount,
          startedAt: startedAt,
          ceoNotes: ceoNotes,
        );
      }

      final generated = (result as AresSuccess<List<CodeArtifact>>).value;
      await log('Doğrulama: ${phase.name} çıktısı kontrol ediliyor.');
      final validation = _validator.validate(<CodeArtifact>[...artifacts, ...generated]);

      if (!validation.isValid) {
        suggestions.addAll(validation.suggestedActions);
        await log('${phase.name}: doğrulama hatası bulundu; self-healing başlıyor.');
        final healed = await _selfHeal(
          phase: phase,
          spec: spec,
          allArtifacts: artifacts,
          phaseArtifacts: generated,
          initialReport: validation,
          onLog: log,
        );
        selfHealingCount += healed.attempts;
        ceoNotes.addAll(healed.ceoNotes);

        if (!healed.success) {
          errors.addAll(healed.errors.map((error) => '${phase.name}: $error'));
          suggestions.addAll(healed.suggestedActions);
          await log('${phase.name}: self-healing başarısız.');
          return _result(
            success: false,
            artifacts: artifacts,
            errors: errors,
            suggestions: suggestions,
            logs: logs,
            retryCount: retryCount,
            selfHealingCount: selfHealingCount,
            startedAt: startedAt,
          );
        }

        artifacts
          ..removeWhere((artifact) =>
              healed.replacedPaths.contains(artifact.relativePath))
          ..addAll(healed.artifacts);
        await log('${phase.name}: self-healing başarılı.');
      } else {
        artifacts.addAll(generated);
      }

      await log('${phase.name}: üretim tamamlandı.');
    }

    await log('Doğrulama: tüm proje artifact\'leri kontrol ediliyor.');
    final projectHealing = await _selfHealWholeProject(
      spec: spec,
      artifacts: artifacts,
      onLog: log,
    );
    selfHealingCount += projectHealing.attempts;
    ceoNotes.addAll(projectHealing.ceoNotes);

    if (!projectHealing.success) {
      errors.addAll(projectHealing.errors);
      suggestions.addAll(projectHealing.suggestedActions);
      await log('Hata: proje geneli self-healing tamamlanamadı.');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    final readiness = buildReadinessService.evaluate(artifacts);
    await log(readiness.ready
        ? 'QA: build hazırlık kontrolü başarılı.'
        : 'QA: build hazırlık kontrolünde eksik veya kırık öğe bulundu.');
    artifacts.add(
      CodeArtifact(
        relativePath: 'docs/BUILD_READINESS.md',
        content: readiness.toMarkdown(),
        type: ArtifactType.markdown,
        generatedBy: 'DevOps',
      ),
    );
    if (!readiness.ready) {
      errors.add('Build hazırlık kontrolü başarısız.');
      suggestions.addAll(readiness.checks.where((check) => check.startsWith('✗')));
    }

    await log('Yazma: güvenli proje köküne dosyalar yazılıyor.');
    late final CodeWriteResult writeResult;
    try {
      final outputArtifacts = artifacts
          .map((artifact) => artifact.copyWith(
                relativePath: 'ARES_Generated_Projects/${_safeOutputFolder(spec.packageName)}/${artifact.relativePath}',
              ))
          .toList(growable: false);
      writeResult = await _codeWriter.writeArtifacts(
        outputArtifacts,
        overwrite: false,
      );
    } catch (error) {
      final message = 'Dosya yazma servisi beklenmeyen bir hata verdi: $error';
      errors.add(message);
      await log('Hata: $message');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    if (writeResult.errors.isNotEmpty) {
      errors.addAll(writeResult.errors);
      await log('Yazma: ${writeResult.errors.length} hata bildirildi.');
    } else {
      await log('Yazma: ${writeResult.writtenPaths.length} dosya başarıyla yazıldı.');
    }

    await log('Doğrulama: son artifact kontrolü yapılıyor.');
    final finalValidation = _validator.validate(artifacts);
    if (!finalValidation.isValid) {
      errors.addAll(finalValidation.errors);
      suggestions.addAll(finalValidation.suggestedActions);
      await log('Hata: son doğrulama başarısız.');
    } else {
      await log('Doğrulama: son kontrol başarılı.');
    }

    final success = errors.isEmpty && finalValidation.isValid && readiness.ready;
    await log(success
        ? 'Tamam: kod üretimi başarıyla tamamlandı.'
        : 'Tamam: kod üretimi hatayla tamamlandı.');

    await _publish(
      type: success ? EventType.systemStopped : EventType.securityAlert,
      message: success ? 'code_generation_completed' : 'code_generation_failed',
      projectName: spec.projectName,
    );

    return _result(
      success: success,
      artifacts: artifacts,
      errors: errors,
      suggestions: suggestions,
      logs: logs,
      retryCount: retryCount,
      selfHealingCount: selfHealingCount,
      startedAt: startedAt,
      ceoNotes: ceoNotes,
      extraMetrics: <String, Object?>{
        'buildReady': readiness.ready,
        'hasMain': readiness.hasMain,
        'hasPubspec': readiness.hasPubspec,
        'hasScreen': readiness.hasScreen,
        'hasAnalysisOptions': readiness.hasAnalysisOptions,
        'brokenCriticalImportCount': readiness.brokenCriticalImports.length,
        'outputRoot': 'ARES_Generated_Projects/${_safeOutputFolder(spec.packageName)}',
      },
    );
  }

  List<String> _aiSetupSuggestions() => const <String>[
        'Ollama veya LM Studio kurulu ve erişilebilir olmalı.',
        'ARES_LOCAL_AI_BASE_URL ve ARES_LOCAL_AI_MODEL değerlerini kontrol edin.',
        'Yerel AI yoksa ARES_FREE_AI_BASE_URL ve ARES_FREE_AI_MODEL ile doğrulanmış ücretsiz endpoint tanımlayın.',
      ];

  String _safeOutputFolder(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'generated_app' : normalized;
  }

  GenerationPlan _createPlan(ProjectSpec spec) {
    return GenerationPlan(
      projectName: 'runtime',
      steps: <GenerationStep>[
        GenerationStep(id: 'scaffold', name: 'Scaffold', description: 'Proje iskeletini oluştur.', order: 1, required: true),
        GenerationStep(id: 'product_manager', name: 'Product Manager', description: 'İsteği ve kabul kriterlerini netleştir.', order: 2, required: true),
        GenerationStep(id: 'architect', name: 'System Architect', description: 'Mimari ve klasör kararlarını üret.', order: 3, required: true),
        GenerationStep(id: 'domain', name: 'Domain', description: 'Domain dosyalarını üret.', order: 4, required: true),
        GenerationStep(id: 'application', name: 'Application', description: 'Application dosyalarını üret.', order: 5, required: true),
        GenerationStep(id: 'presentation', name: 'Presentation', description: 'Presentation dosyalarını üret.', order: 6, required: true),
        GenerationStep(id: 'qa', name: 'QA Engineer', description: 'Test ve kalite çıktıları üret.', order: 7, required: true),
        GenerationStep(id: 'devops', name: 'DevOps / Release', description: 'Build hazırlık ve release belgelerini üret.', order: 8, required: true),
        GenerationStep(id: 'validation', name: 'Doğrulama', description: 'Çıktıları doğrula ve gerektiğinde iyileştir.', order: 9, required: true),
        GenerationStep(id: 'write', name: 'Yazma', description: 'Dosyaları güvenli köke yaz.', order: 10, required: true),
      ],
    ).copyWith(projectName: spec.projectName);
  }

  Future<_PhaseResult> _runPhaseWithRetry({
    required _GenerationPhase phase,
    required ProjectSpec spec,
    required List<CodeArtifact> existingArtifacts,
    required Future<void> Function(String message) onLog,
  }) async {
    var retries = 0;
    AresResult<List<CodeArtifact>>? lastFailure;

    for (var attempt = 0; attempt <= maxRetriesPerStep; attempt++) {
      if (attempt > 0) {
        retries++;
        await onLog('${phase.name}: tekrar denemesi $attempt/${maxRetriesPerStep}.');
      }

      final prompt = _promptBuilder.build(
        role: phase.role,
        projectSpec: spec,
        relevantFiles: _relevantFiles(existingArtifacts, phase.directory),
        fileExcerpts: _previousOutputExcerpts(existingArtifacts, phase.directory),
      );

      try {
        final result = await _llmCodeGenerator.generate(
          prompt,
          costClass: aiCostClass,
          provider: provider,
          model: model,
        );
        if (result is AresSuccess<List<CodeArtifact>>) {
          final ownershipError = _validatePhaseOwnership(phase, result.value);
          if (ownershipError == null) {
            return _PhaseResult(result: result, retries: retries);
          }
          lastFailure = AresFailure<List<CodeArtifact>>(ownershipError);
          await onLog('Hata: $ownershipError');
        } else {
          lastFailure = result;
        }
      } catch (error) {
        lastFailure = AresFailure<List<CodeArtifact>>(
          'LLM çağrısı beklenmeyen bir hata verdi: $error',
        );
      }
    }

    return _PhaseResult(
      result: lastFailure ?? const AresFailure<List<CodeArtifact>>('LLM üretimi başarısız.'),
      retries: retries,
    );
  }

  Future<_HealingResult> _selfHeal({
    required _GenerationPhase phase,
    required ProjectSpec spec,
    required List<CodeArtifact> allArtifacts,
    required List<CodeArtifact> phaseArtifacts,
    required CodeValidationReport initialReport,
    required Future<void> Function(String message) onLog,
  }) async {
    var current = List<CodeArtifact>.from(phaseArtifacts);
    var report = initialReport;
    final notes = <String>[];
    final seenSignatures = <String>{};

    for (var attempt = 1; attempt <= CeoSelfHealService.maxAttempts; attempt++) {
      final signature = '${report.errors.join('|')}|${report.suggestedActions.join('|')}';
      if (!seenSignatures.add(signature)) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: current.map((a) => a.relativePath).toSet(),
          errors: const <String>['Aynı hata tekrarlandı; CEO aynı düzeltmeyi sonsuz kez denemedi.'],
          suggestedActions: report.suggestedActions,
          attempts: attempt - 1,
          ceoNotes: notes,
        );
      }

      final diagnosis = ceoSelfHealService.diagnose(report);
      notes.add('Deneme $attempt: $diagnosis');
      await onLog('CEO: $diagnosis');
      await onLog('CEO: düzeltme denemesi $attempt/${CeoSelfHealService.maxAttempts}.');

      final result = await ceoSelfHealService.repair(
        spec: spec,
        role: phase.role,
        artifacts: current,
        report: report,
      );

      if (result is AresFailure<List<CodeArtifact>>) {
        notes.add('Deneme $attempt: düzeltme üretilemedi.');
        if (attempt == CeoSelfHealService.maxAttempts) {
          return _HealingResult(
            success: false,
            artifacts: current,
            replacedPaths: current.map((a) => a.relativePath).toSet(),
            errors: <String>[result.message, ...report.errors],
            suggestedActions: report.suggestedActions,
            attempts: attempt,
            ceoNotes: notes,
          );
        }
        continue;
      }

      final repaired = (result as AresSuccess<List<CodeArtifact>>).value;
      final merged = _replacePhaseArtifacts(allArtifacts, current, repaired);
      report = _validator.validate(merged);
      if (report.isValid) {
        notes.add('Deneme $attempt: doğrulama başarılı.');
        return _HealingResult(
          success: true,
          artifacts: repaired,
          replacedPaths: current.map((a) => a.relativePath).toSet(),
          errors: const <String>[],
          suggestedActions: const <String>[],
          attempts: attempt,
          ceoNotes: notes,
        );
      }
      current = repaired;
    }

    return _HealingResult(
      success: false,
      artifacts: current,
      replacedPaths: current.map((a) => a.relativePath).toSet(),
      errors: report.errors,
      suggestedActions: report.suggestedActions,
      attempts: CeoSelfHealService.maxAttempts,
      ceoNotes: notes,
    );
  }

  Future<_HealingResult> _selfHealWholeProject({
    required ProjectSpec spec,
    required List<CodeArtifact> artifacts,
    required Future<void> Function(String message) onLog,
  }) async {
    var current = List<CodeArtifact>.from(artifacts);
    var report = _validator.validate(current);
    if (report.isValid) {
      return const _HealingResult(
        success: true,
        artifacts: <CodeArtifact>[],
        replacedPaths: <String>{},
        errors: <String>[],
        suggestedActions: <String>[],
        attempts: 0,
        ceoNotes: <String>[],
      );
    }

    final notes = <String>[];
    final seenSignatures = <String>{};
    for (var attempt = 1; attempt <= CeoSelfHealService.maxAttempts; attempt++) {
      final signature = report.errors.join('|');
      if (!seenSignatures.add(signature)) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: const <String>{},
          errors: const <String>['Aynı proje hatası tekrarlandı; CEO denemeyi durdurdu.'],
          suggestedActions: report.suggestedActions,
          attempts: attempt - 1,
          ceoNotes: notes,
        );
      }

      final affected = _affectedArtifacts(current, report.errors);
      if (affected.isEmpty) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: const <String>{},
          errors: report.errors,
          suggestedActions: report.suggestedActions,
          attempts: attempt,
          ceoNotes: notes,
        );
      }

      final diagnosis = ceoSelfHealService.diagnose(report);
      notes.add('Proje deneme $attempt: $diagnosis');
      await onLog('CEO: $diagnosis');
      var changed = false;
      for (final artifact in affected) {
        final role = _roleFromGeneratedBy(artifact.generatedBy);
        final result = await ceoSelfHealService.repair(
          spec: spec,
          role: role,
          artifacts: <CodeArtifact>[artifact],
          report: report,
        );
        if (result is AresSuccess<List<CodeArtifact>> && result.value.isNotEmpty) {
          current = _replaceArtifacts(current, artifact.relativePath, result.value);
          changed = true;
        }
      }

      if (!changed) {
        notes.add('Proje deneme $attempt: geçerli bir düzeltme üretilemedi.');
        continue;
      }

      report = _validator.validate(current);
      if (report.isValid) {
        artifacts
          ..clear()
          ..addAll(current);
        notes.add('Proje deneme $attempt: doğrulama başarılı.');
        return _HealingResult(
          success: true,
          artifacts: const <CodeArtifact>[],
          replacedPaths: const <String>{},
          errors: const <String>[],
          suggestedActions: const <String>[],
          attempts: attempt,
          ceoNotes: notes,
        );
      }
    }

    return _HealingResult(
      success: false,
      artifacts: current,
      replacedPaths: const <String>{},
      errors: report.errors,
      suggestedActions: report.suggestedActions,
      attempts: CeoSelfHealService.maxAttempts,
      ceoNotes: notes,
    );
  }

  Future<AresResult<List<CodeArtifact>>> _repairArtifact(
    CodegenAgentRole role,
    ProjectSpec spec,
    CodeArtifact artifact,
    CodeValidationReport report,
  ) async {
    final prompt = _buildRepairPrompt(role, spec, <CodeArtifact>[artifact], report);
    try {
      return await _llmCodeGenerator.generate(
        prompt,
        costClass: aiCostClass,
        provider: provider,
        model: model,
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('Self-healing çağrısı başarısız: $error');
    }
  }

  CodegenPrompt _buildRepairPrompt(
    CodegenAgentRole role,
    ProjectSpec spec,
    List<CodeArtifact> artifacts,
    CodeValidationReport report,
  ) {
    final context = artifacts.map((artifact) => '''PATH: ${artifact.relativePath}
GENERATED_BY: ${artifact.generatedBy}
TYPE: ${artifact.type.name}
CONTENT:
${artifact.content}''').join('\n\n');

    return CodegenPrompt(
      role: role,
      systemPrompt: '''Sen DEST-OS ARES Kod Üretim Motorunda çalışan ${role.displayName} ajanısın.
Yalnızca verilen artifact doğrulama hatalarını düzelt.
Çıktı yalnızca geçerli JSON olmalı:
{"artifacts":[{"relativePath":"...","content":"...","type":"dart|yaml|markdown|json|other","generatedBy":"${role.displayName}"}]}
''',
      userPrompt: '''PROJECT_SPEC
projectName: ${spec.projectName}
description: ${spec.description}
packageName: ${spec.packageName}
architecture: ${spec.architecture.name}
features: ${spec.features.join(', ')}
screens: ${spec.screens.join(', ')}

VALIDATION_ERRORS
- ${report.errors.join('\n- ')}

SUGGESTED_ACTIONS
- ${report.suggestedActions.join('\n- ')}

ARTIFACTS_TO_REPAIR
$context

Yalnızca düzeltilmiş artifact JSON'unu döndür.''',
    );
  }

  List<CodeArtifact> _replacePhaseArtifacts(
    List<CodeArtifact> all,
    List<CodeArtifact> oldPhase,
    List<CodeArtifact> repaired,
  ) {
    final oldPaths = oldPhase.map((artifact) => artifact.relativePath).toSet();
    return <CodeArtifact>[...
      all.where((artifact) => !oldPaths.contains(artifact.relativePath)),
      ...repaired,
    ];
  }

  List<CodeArtifact> _replaceArtifacts(
    List<CodeArtifact> source,
    String replacedPath,
    List<CodeArtifact> replacements,
  ) {
    final replacementByPath = <String, CodeArtifact>{
      for (final artifact in replacements) artifact.relativePath: artifact,
    };
    final result = <CodeArtifact>[];
    for (final artifact in source) {
      if (artifact.relativePath == replacedPath) {
        final replacement = replacementByPath[replacedPath];
        if (replacement != null) result.add(replacement);
      } else {
        result.add(artifact);
      }
    }
    for (final replacement in replacements) {
      if (!source.any((artifact) => artifact.relativePath == replacement.relativePath)) {
        result.add(replacement);
      }
    }
    return result;
  }

  List<CodeArtifact> _affectedArtifacts(List<CodeArtifact> artifacts, List<String> errors) {
    return artifacts.where((artifact) => errors.any((error) => error.contains(artifact.relativePath))).toList();
  }

  CodegenAgentRole _roleFromGeneratedBy(String generatedBy) {
    switch (generatedBy.toLowerCase()) {
      case 'productmanager':
      case 'product manager':
        return CodegenAgentRole.productManager;
      case 'architect':
        return CodegenAgentRole.architect;
      case 'qaengineer':
      case 'qa engineer':
        return CodegenAgentRole.qaEngineer;
      case 'devops':
        return CodegenAgentRole.devOps;
      default:
        return CodegenAgentRole.flutterDeveloper;
    }
  }

  String? _validatePhaseOwnership(
    _GenerationPhase phase,
    List<CodeArtifact> generated,
  ) {
    for (final artifact in generated) {
      if (!artifact.relativePath.startsWith(phase.directory)) {
        return '${phase.name} ajanı yetkisi dışındaki dosyayı üretmeye çalıştı: ${artifact.relativePath}';
      }
    }
    final paths = generated.map((artifact) => artifact.relativePath).toList();
    if (paths.toSet().length != paths.length) {
      return '${phase.name} aynı dosya yolunu birden fazla artifact ile üretti.';
    }
    return null;
  }

  /// Önceki ajanların ürettiği dosyalardan, token tasarrufu için kısaltılmış
  /// alıntılar verir. Böylece her ajan öncekinin gerçek çıktısını görür.
  Map<String, String> _previousOutputExcerpts(List<CodeArtifact> artifacts, String directory) {
    const perFileLimit = 1200;
    const totalLimit = 6000;
    final candidates = artifacts
        .where((artifact) => !artifact.relativePath.startsWith(directory))
        .toList()
      ..sort((a, b) {
        final aDoc = a.relativePath.startsWith('docs/') ? 0 : 1;
        final bDoc = b.relativePath.startsWith('docs/') ? 0 : 1;
        if (aDoc != bDoc) return aDoc.compareTo(bDoc);
        return a.relativePath.compareTo(b.relativePath);
      });
    final excerpts = <String, String>{};
    var used = 0;
    for (final artifact in candidates) {
      if (used >= totalLimit) break;
      final room = totalLimit - used;
      final limit = room < perFileLimit ? room : perFileLimit;
      final text = artifact.content.length > limit
          ? '${artifact.content.substring(0, limit)}\n...(kisaltildi)'
          : artifact.content;
      excerpts[artifact.relativePath] = text;
      used += text.length;
    }
    return Map<String, String>.unmodifiable(excerpts);
  }

  List<String> _relevantFiles(List<CodeArtifact> artifacts, String directory) {
    final paths = artifacts
        .where((artifact) =>
            (directory.startsWith('docs/') && artifact.relativePath.startsWith('docs/')) ||
            artifact.relativePath.startsWith(directory))
        .map((artifact) => artifact.relativePath)
        .toSet()
        .toList()
      ..sort();
    return List.unmodifiable(paths);
  }

  GenerationResult _result({
    required bool success,
    required List<CodeArtifact> artifacts,
    required List<String> errors,
    required List<String> suggestions,
    required List<String> logs,
    required int retryCount,
    required int selfHealingCount,
    required DateTime startedAt,
    List<String> ceoNotes = const <String>[],
    Map<String, Object?> extraMetrics = const <String, Object?>{},
  }) {
    return GenerationResult(
      success: success,
      artifacts: artifacts,
      errors: errors,
      suggestedActions: suggestions.toSet().toList(),
      attemptCount: 1 + retryCount + selfHealingCount,
      ceoNotes: ceoNotes,
      metrics: <String, Object?>{
        'artifactCount': artifacts.length,
        'errorCount': errors.length,
        'retryCount': retryCount,
        'selfHealingCount': selfHealingCount,
        'attemptCount': 1 + retryCount + selfHealingCount,
        'ceoNotes': List.unmodifiable(ceoNotes),
        'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
        'logCount': logs.length,
        'logs': List.unmodifiable(logs),
        ...extraMetrics,
      },
    );
  }

  Future<void> _publish({
    required EventType type,
    required String message,
    required String projectName,
  }) async {
    final bus = eventBus;
    if (bus == null) return;
    try {
      await bus.publish(
        EventEnvelope(
          id: 'codegen-${DateTime.now().microsecondsSinceEpoch}',
          type: type,
          createdAt: DateTime.now(),
          source: 'CodeGenerationOrchestrator',
          payload: <String, Object?>{
            'message': message,
            'projectName': projectName,
          },
        ),
      );
    } catch (error) {
      logger?.call('Event Bus bildirimi başarısız: $error');
    }
  }
}

class _GenerationPhase {
  const _GenerationPhase({
    required this.name,
    required this.role,
    required this.directory,
  });

  final String name;
  final CodegenAgentRole role;
  final String directory;
}

class _PhaseResult {
  const _PhaseResult({required this.result, required this.retries});

  final AresResult<List<CodeArtifact>> result;
  final int retries;
}

class _HealingResult {
  const _HealingResult({
    required this.success,
    required this.artifacts,
    required this.replacedPaths,
    required this.errors,
    required this.suggestedActions,
    required this.attempts,
    this.ceoNotes = const <String>[],
  });

  final bool success;
  final List<CodeArtifact> artifacts;
  final Set<String> replacedPaths;
  final List<String> errors;
  final List<String> suggestedActions;
  final int attempts;
  final List<String> ceoNotes;
}
