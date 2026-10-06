import '../../core/security/cost_policy.dart';

class AiRoutingDecision {
  const AiRoutingDecision({
    required this.provider,
    required this.model,
    required this.costClass,
    required this.reason,
    this.requiresApproval = false,
  });

  final String provider;
  final String model;
  final AiCostClass costClass;
  final String reason;
  final bool requiresApproval;
}
