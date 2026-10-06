import '../tasks/task.dart';
import 'runtime_state.dart';

class RuntimeTask {
  RuntimeTask({
    required this.task,
    this.state = RuntimeState.created,
    this.attempt = 0,
    this.workerId,
    this.leaseId,
    this.lastError,
  });

  final AresTask task;
  RuntimeState state;
  int attempt;
  String? workerId;
  String? leaseId;
  String? lastError;

  RuntimeTask copy() {
    return RuntimeTask(
      task: task,
      state: state,
      attempt: attempt,
      workerId: workerId,
      leaseId: leaseId,
      lastError: lastError,
    );
  }
}
