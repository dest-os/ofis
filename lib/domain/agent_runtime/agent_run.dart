import 'agent_run_status.dart';

class AgentRun {
  AgentRun({
    required this.runId,
    required this.taskId,
    required this.agentId,
    this.status = AgentRunStatus.created,
    this.attempt = 0,
    this.startedAt,
    this.completedAt,
    this.error,
  });

  final String runId;
  final String taskId;
  final String agentId;
  AgentRunStatus status;
  int attempt;
  DateTime? startedAt;
  DateTime? completedAt;
  String? error;
}
