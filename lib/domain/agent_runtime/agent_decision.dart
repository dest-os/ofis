class AgentDecision {
  const AgentDecision({
    required this.action,
    this.reason,
    this.toolName,
    this.requiresApproval = false,
  });

  final String action;
  final String? reason;
  final String? toolName;
  final bool requiresApproval;
}
