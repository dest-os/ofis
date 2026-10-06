class RuntimeCheckpoint {
  const RuntimeCheckpoint({
    required this.id,
    required this.taskId,
    required this.runId,
    required this.createdAt,
    required this.state,
    required this.attempt,
    this.payload = const <String, Object?>{},
  });

  final String id;
  final String taskId;
  final String runId;
  final DateTime createdAt;
  final String state;
  final int attempt;
  final Map<String, Object?> payload;
}
