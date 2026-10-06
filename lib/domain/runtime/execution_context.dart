class ExecutionContext {
  const ExecutionContext({
    required this.runId,
    required this.taskId,
    required this.startedAt,
    this.projectId,
    this.agentId,
    this.metadata = const <String, Object?>{},
  });

  final String runId;
  final String taskId;
  final DateTime startedAt;
  final String? projectId;
  final String? agentId;
  final Map<String, Object?> metadata;

  ExecutionContext copyWith({
    String? runId,
    String? taskId,
    DateTime? startedAt,
    String? projectId,
    String? agentId,
    Map<String, Object?>? metadata,
  }) {
    return ExecutionContext(
      runId: runId ?? this.runId,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      projectId: projectId ?? this.projectId,
      agentId: agentId ?? this.agentId,
      metadata: metadata ?? this.metadata,
    );
  }
}
