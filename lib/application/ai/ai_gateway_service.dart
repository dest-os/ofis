import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import '../../domain/runtime/ai_runtime_request.dart';
import '../../domain/runtime/runtime_result.dart';
import '../runtime/local_ai_runtime.dart';
import '../runtime/paid_ai_runtime_gate.dart';
import 'ai_request_router.dart';

class AiGatewayService {
  const AiGatewayService({
    required this.router,
    required this.localRuntime,
    this.paidGate = const PaidAiRuntimeGate(),
  });

  final AiRequestRouter router;
  final LocalAiRuntime localRuntime;
  final PaidAiRuntimeGate paidGate;

  Future<RuntimeResult> execute(AiRequest request) async {
    final route = router.route(request);
    final runtimeRequest = AiRuntimeRequest(
      instruction: request.instruction,
      costClass: route.costClass,
      provider: route.provider,
      model: route.model,
    );
    final gate = paidGate.evaluate(runtimeRequest);
    if (!gate.mayRun) {
      return RuntimeResult(
        status: RuntimeResultStatus.waitingApproval,
        error: gate.reason,
        metadata: <String, Object?>{
          'provider': route.provider,
          'model': route.model,
          'costClass': route.costClass.name,
        },
      );
    }
    if (route.costClass == AiCostClass.local ||
        route.costClass == AiCostClass.free ||
        route.costClass == AiCostClass.limitedFree) {
      return localRuntime.run(runtimeRequest);
    }
    return const RuntimeResult(
      status: RuntimeResultStatus.waitingApproval,
      error: 'AI sağlayıcısı için güvenli çalışma yolu bulunamadı.',
    );
  }

  Future<AiResponse> executeLegacy(AiRequest request) async {
    final result = await execute(request);
    return AiResponse(
      text: result.output?.toString() ?? result.error ?? '',
      modelName: 'ARES-AI-Gateway',
    );
  }
}
