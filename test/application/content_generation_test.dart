import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/codegen/code_validator_service.dart';
import 'package:dest_os_ares/application/codegen/code_writer_service.dart';
import 'package:dest_os_ares/application/content/content_generation_orchestrator.dart';
import 'package:dest_os_ares/core/result/ares_result.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/ai/ai_request.dart';
import 'package:dest_os_ares/domain/ai/ai_response.dart';
import 'package:dest_os_ares/domain/content/content_mode.dart';
import 'package:dest_os_ares/infrastructure/codegen/file_system_writer.dart';
import 'package:dest_os_ares/application/ai/ai_gateway.dart';

void main() {
  test('video üretim sözleşmesi gerçek artifact paketi oluşturur', () async {
    final root = await Directory.systemTemp.createTemp('ares_video_');
    addTearDown(() => root.delete(recursive: true));
    final gateway = _SequenceGateway(<String>[
      _json('brief.md', '# Brief'),
      _json('architecture.md', '# Architecture'),
      jsonEncode({'artifacts': [
        {'relativePath': 'video_brief.md', 'content': '# Video', 'type': 'markdown', 'generatedBy': 'SpecialistProducer'},
        {'relativePath': 'script.md', 'content': '# Script', 'type': 'markdown', 'generatedBy': 'SpecialistProducer'},
        {'relativePath': 'shot_list.md', 'content': '# Shots', 'type': 'markdown', 'generatedBy': 'SpecialistProducer'},
        {'relativePath': 'voiceover_script.md', 'content': '# Voice', 'type': 'markdown', 'generatedBy': 'SpecialistProducer'},
        {'relativePath': 'captions.srt', 'content': '1\n00:00:00,000 --> 00:00:02,000\nMerhaba\n', 'type': 'other', 'generatedBy': 'SpecialistProducer'},
        {'relativePath': 'thumbnail_prompt.md', 'content': '# Thumb', 'type': 'markdown', 'generatedBy': 'SpecialistProducer'},
        {'relativePath': 'production_checklist.md', 'content': '# ffmpeg render plan', 'type': 'markdown', 'generatedBy': 'DevOps'},
      ]}),
      _json('quality_checklist.md', '# QA'),
      _json('production_checklist.md', '# ffmpeg render plan'),
    ]);
    final service = ContentGenerationOrchestrator(
      gateway: gateway,
      writer: CodeWriterService(writer: FileSystemWriter(rootDirectory: root)),
      validator: const CodeValidatorService(),
      costClass: AiCostClass.local,
    );
    final result = await service.generate(mode: ContentMode.video, request: '60 saniyelik verimlilik videosu üret');
    expect(result.success, isTrue);
    expect(result.artifacts.map((a) => a.relativePath), contains('captions.srt'));
    expect(gateway.calls, 5);
  });

  test('paid ve unknown içerik üretimi gate tarafından durdurulur', () async {
    final gateway = _SequenceGateway(const <String>[]);
    final service = ContentGenerationOrchestrator(
      gateway: gateway,
      writer: CodeWriterService(writer: FileSystemWriter(rootDirectory: Directory.systemTemp)),
      costClass: AiCostClass.unknown,
    );
    final result = await service.generate(mode: ContentMode.general, request: 'Bir ürün açıklaması yaz');
    expect(result.success, isFalse);
    expect(gateway.calls, 0);
  });
}

String _json(String path, String content) => jsonEncode({'artifacts': [
  {'relativePath': path, 'content': content, 'type': 'markdown', 'generatedBy': 'test'},
]});

class _SequenceGateway implements AresAiGateway {
  _SequenceGateway(this.responses);
  final List<String> responses;
  int calls = 0;
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    if (calls >= responses.length) return const AresFailure<AiResponse>('no fake response');
    final value = responses[calls++];
    return AresSuccess<AiResponse>(AiResponse(text: value, modelName: 'fake'));
  }
}
