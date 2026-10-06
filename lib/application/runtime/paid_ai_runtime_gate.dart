import '../../core/security/cost_policy.dart';
import '../../domain/runtime/ai_runtime_request.dart';

enum AiRuntimeGateDecision { allowed, waitingApproval, blocked }

class AiRuntimeGateResult {
  const AiRuntimeGateResult({
    required this.decision,
    required this.reason,
  });

  final AiRuntimeGateDecision decision;
  final String reason;

  bool get mayRun => decision == AiRuntimeGateDecision.allowed;
}

class PaidAiRuntimeGate {
  const PaidAiRuntimeGate();

  AiRuntimeGateResult evaluate(AiRuntimeRequest request) {
    switch (request.costClass) {
      case AiCostClass.local:
      case AiCostClass.free:
      case AiCostClass.limitedFree:
        return const AiRuntimeGateResult(
          decision: AiRuntimeGateDecision.allowed,
          reason: 'Maliyet politikası gereği çalıştırılabilir.',
        );
      case AiCostClass.paid:
        return const AiRuntimeGateResult(
          decision: AiRuntimeGateDecision.waitingApproval,
          reason: 'Ücretli AI için İbrahim tarafından açık onay gerekir.',
        );
      case AiCostClass.unknown:
        return const AiRuntimeGateResult(
          decision: AiRuntimeGateDecision.waitingApproval,
          reason: 'Fiyat/lisans bilinmiyor; ücretsiz kabul edilemez.',
        );
    }
  }
}
