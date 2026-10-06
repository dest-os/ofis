import 'runtime_mode.dart';
import 'runtime_status.dart';

class RuntimeSnapshot {
  const RuntimeSnapshot({
    required this.status,
    required this.mode,
    required this.startedAt,
    required this.lastHeartbeat,
    required this.activeTasks,
    required this.activeAgents,
  });

  final RuntimeStatus status;
  final RuntimeMode mode;
  final DateTime? startedAt;
  final DateTime? lastHeartbeat;
  final int activeTasks;
  final int activeAgents;
}
