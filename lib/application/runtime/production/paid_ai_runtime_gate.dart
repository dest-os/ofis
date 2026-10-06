import '../../../core/security/cost_policy.dart';

class PaidAiRuntimeGate {
  const PaidAiRuntimeGate();

  bool mayExecute(AiCostClass costClass, {required bool userApproved}) {
    if (costClass == AiCostClass.paid || costClass == AiCostClass.unknown) {
      return userApproved;
    }
    return CostPolicy.mayRunWithoutUserApproval(costClass);
  }

  String status(AiCostClass costClass, {required bool userApproved}) {
    if (mayExecute(costClass, userApproved: userApproved)) return 'READY';
    return 'WAITING_APPROVAL';
  }
}
