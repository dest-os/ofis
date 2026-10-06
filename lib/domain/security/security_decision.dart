enum SecurityDecisionType { allow, deny, requireApproval }

class SecurityDecision {
  final SecurityDecisionType type;
  final String reason;
  final String? approvalId;

  const SecurityDecision({required this.type, required this.reason, this.approvalId});

  bool get allowed => type == SecurityDecisionType.allow;
}
