class AgentContext {
  const AgentContext({
    required this.runId,
    required this.taskId,
    required this.agentId,
    required this.instruction,
    this.memory = const <String, Object?>{},
    this.archive = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String runId;
  final String taskId;
  final String agentId;
  final String instruction;
  final Map<String, Object?> memory;
  final Map<String, Object?> archive;
  final Map<String, Object?> metadata;
}
