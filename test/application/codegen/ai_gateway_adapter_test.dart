import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/ai/ai_request.dart';
import 'package:dest_os_ares/infrastructure/codegen/fallback_llm_code_generator.dart';
import 'package:dest_os_ares/infrastructure/codegen/free_remote_ai_gateway_adapter.dart';
import 'package:dest_os_ares/infrastructure/codegen/local_ai_gateway_adapter.dart';
import 'package:dest_os_ares/infrastructure/codegen/llm_code_generator.dart';
import 'package:dest_os_ares/infrastructure/codegen/openai_compatible_transport.dart';
import 'package:dest_os_ares/application/codegen/prompt_builder_service.dart';
import 'package:dest_os_ares/domain/codegen/project_spec.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/domain/codegen/architecture_type.dart';
import 'package:dest_os_ares/core/result/ares_result.dart';
import 'package:dest_os_ares/domain/ai/ai_response.dart';

void main() {
  test('LocalAiGatewayAdapter OpenAI uyumlu cevabı parse eder', () async {
    final adapter = LocalAiGatewayAdapter(
      baseUrl: 'http://localhost:11434',
      model: 'qwen3:4b',
      transport: _FakeTransport((_) async => const AiHttpResponse(
            statusCode: 200,
            body: '{"model":"qwen3:4b","choices":[{"message":{"content":"{\\"artifacts\\":[]}"}}]}',
          )),
    );

    final result = await adapter.generate(
      const AiRequest(instruction: 'test', costClass: AiCostClass.local),
    );

    expect(result, isA<AresSuccess<AiResponse>>());
    expect((result as AresSuccess<AiResponse>).value.text, contains('artifacts'));
  });

  test('FreeRemoteAiGatewayAdapter API key istemciye kodlanmadan header olarak gönderilir', () async {
    final transport = _FakeTransport((request) async {
      expect(request.headers['Authorization'], 'Bearer runtime-key');
      expect(request.uri.toString(), 'https://example.com/v1/chat/completions');
      return const AiHttpResponse(
        statusCode: 200,
        body: '{"model":"free-model","choices":[{"message":{"content":"ok"}}]}',
      );
    });
    final adapter = FreeRemoteAiGatewayAdapter(
      baseUrl: 'https://example.com/v1',
      model: 'free-model',
      apiKey: 'runtime-key',
      transport: transport,
    );

    final result = await adapter.generate(
      const AiRequest(instruction: 'test', costClass: AiCostClass.free),
    );

    expect(result, isA<AresSuccess<AiResponse>>());
  });

  test('FallbackLlmCodeGenerator local başarısız olunca ücretsiz yolu dener', () async {
    final generator = FallbackLlmCodeGenerator(
      local: const _FailingGenerator(),
      free: MockLlmCodeGenerator(
        responseJson: '{"artifacts":[]}',
      ),
    );
    final prompt = PromptBuilderService().build(
      role: CodegenAgentRole.flutterDeveloper,
      projectSpec: ProjectSpec(
        projectName: 'Test',
        description: 'Test uygulaması üret',
        packageName: 'test_app',
        features: <String>['Test'],
        architecture: ArchitectureType.clean,
        requiredPackages: <String>[],
        screens: <String>['Ana'],
        acceptanceCriteria: <String>['main.dart oluşturulmalı'],
        includeTests: true,
        includeReadme: true,
      ),
      relevantFiles: const <String>[],
    );

    final result = await generator.generate(prompt);
    expect(result, isA<AresSuccess<List>>());
  });
}

class _FakeTransport implements AiHttpTransport {
  _FakeTransport(this.handler);

  final Future<AiHttpResponse> Function(_TransportRequest request) handler;

  @override
  Future<AiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 90),
  }) => handler(_TransportRequest(uri: uri, headers: headers, body: body));
}

class _TransportRequest {
  const _TransportRequest({required this.uri, required this.headers, required this.body});
  final Uri uri;
  final Map<String, String> headers;
  final Map<String, Object?> body;
}

class _FailingGenerator implements LlmCodeGenerator {
  const _FailingGenerator();

  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    return const AresFailure<List<CodeArtifact>>('local unavailable');
  }
}
