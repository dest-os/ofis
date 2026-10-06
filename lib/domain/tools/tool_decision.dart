enum ToolDecisionType {
  allow,
  deny,
  requireApproval,
}

class ToolDecision {
  const ToolDecision({
    required this.type,
    required this.reason,
  });

  final ToolDecisionType type;
  final String reason;

  bool get allowed => type == ToolDecisionType.allow;
}
