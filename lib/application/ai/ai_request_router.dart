import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_routing_decision.dart';

abstract interface class AiRequestRouter {
  AiRoutingDecision route(AiRequest request);
}

class PolicyFirstAiRequestRouter implements AiRequestRouter {
  const PolicyFirstAiRequestRouter({
    this.localProvider = 'local',
    this.localModel = 'verified-local-model',
  });

  final String localProvider;
  final String localModel;

  @override
  AiRoutingDecision route(AiRequest request) {
    if (request.costClass == AiCostClass.local) {
      return AiRoutingDecision(
        provider: localProvider,
        model: localModel,
        costClass: AiCostClass.local,
        reason: 'Yerel AI önceliği seçildi.',
      );
    }
    if (request.costClass == AiCostClass.free ||
        request.costClass == AiCostClass.limitedFree) {
      return AiRoutingDecision(
        provider: 'verified-free-provider',
        model: 'verified-free-model',
        costClass: request.costClass,
        reason: 'Doğrulanmış ücretsiz/limitli ücretsiz yol seçildi.',
      );
    }
    return AiRoutingDecision(
      provider: 'policy-router',
      model: 'unselected',
      costClass: request.costClass,
      reason: 'Ücretli veya bilinmeyen AI için onay gerekir.',
      requiresApproval: true,
    );
  }
}
