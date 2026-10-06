import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../application/codegen/prompt_builder_service.dart';
import '../../application/decision/decision_engine.dart';
import '../../application/runtime/paid_ai_runtime_gate.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/runtime/ai_runtime_request.dart';

/// LLM kod üretimi için altyapı sözleşmesi.
abstract interface class LlmCodeGenerator {
  /// Generates code artifacts for [prompt].
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass,
    String? provider,
    String? model,
  });
}

/// Mevcut ARES AI Gateway üzerinden gerçek API entegrasyonuna hazır üreticidir.
/// Gateway'in kendisi sağlayıcı/API ayrıntılarını yönetir.
class ApiLlmCodeGenerator implements LlmCodeGenerator {
  /// Creates an API-backed code generator using the existing ARES gateway.
  ApiLlmCodeGenerator({
    required this.gateway,
    PaidAiRuntimeGate? paidGate,
    DecisionEngine? decisionEngine,
  })  : paidGate = paidGate ?? const PaidAiRuntimeGate(),
        decisionEngine = decisionEngine ?? DecisionEngine();

  /// Existing ARES AI Gateway used for model requests.
  final AresAiGateway gateway;

  /// Existing gate that blocks paid AI without the required approval.
  final PaidAiRuntimeGate paidGate;

  /// Existing decision engine used before a model request is sent.
  final DecisionEngine decisionEngine;

  /// Sends a structured code-generation request through the existing ARES AI Gateway.
  ///
  /// The [costClass] is evaluated by [paidGate] before the gateway is called.
  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    final runtimeRequest = AiRuntimeRequest(
      instruction: '${prompt.systemPrompt}\n\n${prompt.userPrompt}',
      costClass: costClass,
      provider: provider,
      model: model,
      metadata: <String, Object?>{
        'feature': 'code_generation',
        'agentRole': prompt.role.displayName,
        'structuredOutput': true,
      },
    );

    final gate = paidGate.evaluate(runtimeRequest);
    if (!gate.mayRun) {
      return AresFailure<List<CodeArtifact>>(
        'Kod üretimi başlatılmadı: ${gate.reason}',
      );
    }

    final decision = decisionEngine.decide(
      id: 'codegen-${prompt.role.name}',
      archiveAvailable: false,
      localAiAvailable:
          costClass == AiCostClass.local,
      freeAiAvailable:
          costClass == AiCostClass.free ||
          costClass == AiCostClass.limitedFree,
      paidAiAvailable: costClass == AiCostClass.paid,
    );

    if (decision.requiresUserApproval) {
      return AresFailure<List<CodeArtifact>>(
        'Kod üretimi için İbrahim onayı gerekiyor: ${decision.reason}',
      );
    }

    if (decision.type.name == 'defer') {
      return AresFailure<List<CodeArtifact>>(
        'Kod üretimi ertelendi: ${decision.reason}',
      );
    }

    try {
      final response = await gateway.generate(
        AiRequest(
          instruction: runtimeRequest.instruction,
          costClass: costClass,
        ),
      );

      if (response is AresFailure<AiResponse>) {
        return AresFailure<List<CodeArtifact>>(
          'LLM isteği başarısız: ${response.message}',
        );
      }

      if (response is! AresSuccess<AiResponse>) {
        return const AresFailure<List<CodeArtifact>>(
          'LLM isteği beklenmeyen bir sonuç döndürdü.',
        );
      }

      return _parseStructuredOutput(
        response.value.text,
        fallbackGeneratedBy: prompt.role.displayName,
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>(
        'LLM çağrısı sırasında hata oluştu: $error',
      );
    }
  }

  /// Parses the structured JSON response returned by an LLM.
  AresResult<List<CodeArtifact>> _parseStructuredOutput(
    String raw,
    {required String fallbackGeneratedBy},
  ) {
    try {
      final decoded = jsonDecode(raw);
      final dynamic rawArtifacts = decoded is Map<String, dynamic>
          ? decoded['artifacts']
          : decoded;

      if (rawArtifacts is! List) {
        return const AresFailure<List<CodeArtifact>>(
          'LLM çıktısı geçersiz: "artifacts" listesi bulunamadı.',
        );
      }

      final artifacts = <CodeArtifact>[];
      for (var index = 0; index < rawArtifacts.length; index++) {
        final item = rawArtifacts[index];
        if (item is! Map) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $index numaralı artifact nesne değil.',
          );
        }

        final path = item['relativePath'];
        final content = item['content'];
        final typeValue = item['type'];
        final generatedBy = item['generatedBy'] ?? fallbackGeneratedBy;

        if (path is! String || path.trim().isEmpty) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $index numaralı artifact için relativePath eksik.',
          );
        }
        if (content is! String) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $path için content metin değil.',
          );
        }
        if (generatedBy is! String || generatedBy.trim().isEmpty) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $path için generatedBy eksik.',
          );
        }

        final type = _artifactType(typeValue);
        if (type == null) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $path için artifact type tanınmıyor.',
          );
        }

        if (_isUnsafeRelativePath(path)) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı reddedildi: güvenli olmayan dosya yolu "$path".',
          );
        }

        artifacts.add(
          CodeArtifact(
            relativePath: path,
            content: content,
            type: type,
            generatedBy: generatedBy,
          ),
        );
      }

      return AresSuccess<List<CodeArtifact>>(List.unmodifiable(artifacts));
    } on FormatException catch (error) {
      return AresFailure<List<CodeArtifact>>(
        'LLM çıktısı geçerli JSON değil: ${error.message}',
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>(
        'LLM çıktısı CodeArtifact formatına çevrilemedi: $error',
      );
    }
  }

  ArtifactType? _artifactType(Object? value) {
    if (value is! String) {
      return null;
    }

    for (final type in ArtifactType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  bool _isUnsafeRelativePath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return normalized.startsWith('/') ||
        normalized.startsWith('~/') ||
        normalized.split('/').contains('..') ||
        RegExp(r'^[A-Za-z]:/').hasMatch(normalized);
  }
}

/// Gerçek ağ/API çağrısı yapmadan kod üretim akışını test etmek için kullanılır.
class MockLlmCodeGenerator implements LlmCodeGenerator {
  /// Creates a mock generator with an optional fixed JSON response.
  ///
  /// [responseBuilder] can return a different JSON payload for each prompt,
  /// which is useful for multi-phase orchestrator tests.
  const MockLlmCodeGenerator({this.responseJson, this.responseBuilder});

  /// Fixed JSON response returned when [responseBuilder] is not supplied.
  final String? responseJson;

  /// Optional callback used to create a response from the current prompt.
  final String Function(CodegenPrompt prompt)? responseBuilder;

  /// Generates a deterministic mock response without network access.
  /// Generates a deterministic structured response for tests without network access.
  ///
  /// Paid and unknown cost classes remain blocked even in the mock implementation.
  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    if (costClass == AiCostClass.paid || costClass == AiCostClass.unknown) {
      return const AresFailure<List<CodeArtifact>>(
        'Mock kod üreticisi de ücretli/bilinmeyen maliyetli AI kullanımını onaysız çalıştırmaz.',
      );
    }

    final json = responseBuilder?.call(prompt) ?? responseJson ??
        jsonEncode(<String, Object?>{
          'artifacts': <Map<String, Object?>>[
            <String, Object?>{
              'relativePath': 'lib/generated/generated_code.dart',
              'content': '// Mock generated by ARES Codegen.\n',
              'type': 'dart',
              'generatedBy': prompt.role.displayName,
            },
          ],
        });

    final parser = ApiLlmCodeGenerator(
      gateway: _UnusedGateway(),
    );
    return parser._parseStructuredOutput(
      json,
      fallbackGeneratedBy: prompt.role.displayName,
    );
  }
}

class _UnusedGateway implements AresAiGateway {
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    return const AresFailure<AiResponse>(
      'Mock parser gerçek ARES AI Gateway çağrısı yapmaz.',
    );
  }
}
