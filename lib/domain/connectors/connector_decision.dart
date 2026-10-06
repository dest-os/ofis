enum ConnectorDecisionType { allow, deny, requireApproval }

class ConnectorDecision {
  const ConnectorDecision({required this.type, required this.reason});

  final ConnectorDecisionType type;
  final String reason;
}
