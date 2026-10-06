import '../../core/security/cost_policy.dart';

class AiRequest {
  const AiRequest({
    required this.instruction,
    required this.costClass,
  });

  final String instruction;
  final AiCostClass costClass;
}
