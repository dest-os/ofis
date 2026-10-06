import '../../application/ai/ai_gateway.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';

/// Local-first ARES gateway with an explicitly configured free remote fallback.
class FallbackAresAiGateway implements AresAiGateway {
  /// Creates the fallback gateway.
  const FallbackAresAiGateway({required this.local, this.free});

  /// Local Ollama/LM Studio gateway.
  final AresAiGateway local;

  /// Optional free remote gateway.
  final AresAiGateway? free;

  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    if (request.costClass == AiCostClass.paid || request.costClass == AiCostClass.unknown) {
      return const AresFailure<AiResponse>('Paid/unknown AI yolu otomatik olarak açılmaz.');
    }
    final localResult = await local.generate(
      AiRequest(instruction: request.instruction, costClass: AiCostClass.local),
    );
    if (localResult is AresSuccess<AiResponse>) return localResult;
    final remote = free;
    if (remote == null) return localResult;
    final remoteClass = request.costClass == AiCostClass.limitedFree
        ? AiCostClass.limitedFree
        : AiCostClass.free;
    final remoteResult = await remote.generate(
      AiRequest(instruction: request.instruction, costClass: remoteClass),
    );
    if (remoteResult is AresSuccess<AiResponse>) return remoteResult;
    final localMessage = localResult is AresFailure<AiResponse> ? localResult.message : 'Yerel AI başarısız.';
    final remoteMessage = remoteResult is AresFailure<AiResponse> ? remoteResult.message : 'Ücretsiz AI başarısız.';
    return AresFailure<AiResponse>('Yerel ve ücretsiz AI başarısız. Yerel: $localMessage Uzak: $remoteMessage');
  }
}
