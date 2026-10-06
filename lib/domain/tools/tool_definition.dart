import 'tool_kind.dart';
import 'tool_risk_level.dart';

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.riskLevel,
    this.enabled = true,
    this.requiresCredential = false,
    this.externalWrite = false,
  });

  final String id;
  final String name;
  final String description;
  final ToolKind kind;
  final ToolRiskLevel riskLevel;
  final bool enabled;
  final bool requiresCredential;
  final bool externalWrite;

  bool get requiresApproval =>
      riskLevel.requiresApproval || externalWrite;
}
