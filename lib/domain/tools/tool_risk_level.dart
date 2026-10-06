enum ToolRiskLevel {
  low,
  medium,
  high,
  critical,
}

extension ToolRiskLevelX on ToolRiskLevel {
  String get value => name.toUpperCase();

  bool get requiresApproval =>
      this == ToolRiskLevel.high || this == ToolRiskLevel.critical;
}
