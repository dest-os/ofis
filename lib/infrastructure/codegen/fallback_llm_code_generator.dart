import '../../application/codegen/prompt_builder_service.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/codegen/code_artifact.dart';
import 'llm_code_generator.dart';

/// Routes generation from local AI to an explicitly configured free remote AI.
class FallbackLlmCodeGenerator implements LlmCodeGenerator {
  /// Creates a local-first generator with an optional free fallback.
  const FallbackLlmCodeGenerator({required this.local, this.free, this.freeCostClass = AiCostClass.free});

  /// Local generator attempted first.
  final LlmCodeGenerator local;

  /// Free/limited-free generator attempted after local failure.
  final LlmCodeGenerator? free;

  /// Cost classification applied to the remote fallback.
  final AiCostClass freeCostClass;

  /// Tries local first, then free, while each route keeps its own cost gate.
  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    if (costClass == AiCostClass.paid || costClass == AiCostClass.unknown) {
      return const AresFailure<List<CodeArtifact>>(
        'Fallback kod üreticisi ücretli veya bilinmeyen maliyetli AI yolunu otomatik açmaz.',
      );
    }
    final localResult = await local.generate(
      prompt,
      costClass: AiCostClass.local,
      provider: provider,
      model: model,
    );
    if (localResult is AresSuccess<List<CodeArtifact>>) return localResult;

    final freeGenerator = free;
    if (freeGenerator == null) return localResult;

    final freeResult = await freeGenerator.generate(
      prompt,
      costClass: freeCostClass,
      provider: provider,
      model: model,
    );
    if (freeResult is AresSuccess<List<CodeArtifact>>) return freeResult;

    final localMessage = localResult is AresFailure<List<CodeArtifact>>
        ? localResult.message
        : 'Yerel AI başarısız oldu.';
    final freeMessage = freeResult is AresFailure<List<CodeArtifact>>
        ? freeResult.message
        : 'Ücretsiz uzak AI başarısız oldu.';
    return AresFailure<List<CodeArtifact>>(
      'Yerel AI ve ücretsiz uzak AI üretimi başarısız. Yerel: $localMessage Uzak: $freeMessage',
    );
  }
}
