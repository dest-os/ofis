class AgentExecutionContract {
  const AgentExecutionContract({
    required this.taskId,
    required this.runId,
    required this.instruction,
    this.acceptanceCriteria = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String taskId;
  final String runId;
  final String instruction;
  final List<String> acceptanceCriteria;
  final Map<String, Object?> metadata;
}
