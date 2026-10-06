enum RiskLevel { low, medium, high, critical }

extension RiskLevelX on RiskLevel {
  bool get requiresApproval => this == RiskLevel.high || this == RiskLevel.critical;
}
