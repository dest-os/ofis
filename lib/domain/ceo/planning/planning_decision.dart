enum PlanningDecisionType {
  proceed,
  useArchive,
  useLocalAi,
  useFreeAi,
  waitApproval,
  revise,
  reject,
}

class PlanningDecision {
  const PlanningDecision({required this.type, required this.reason});

  final PlanningDecisionType type;
  final String reason;
}
