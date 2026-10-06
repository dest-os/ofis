class ToolRequest {
  const ToolRequest({
    required this.id,
    required this.toolId,
    required this.action,
    required this.createdAt,
    this.taskId,
    this.agentId,
    this.parameters = const <String, Object?>{},
  });

  final String id;
  final String toolId;
  final String action;
  final DateTime createdAt;
  final String? taskId;
  final String? agentId;
  final Map<String, Object?> parameters;
}
