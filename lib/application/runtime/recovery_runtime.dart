import '../../domain/runtime/checkpoint.dart';
import '../../domain/runtime/runtime_state.dart';
import '../../domain/runtime/runtime_task.dart';
import 'checkpoint_repository.dart';

class RecoveryRuntime {
  RecoveryRuntime({required CheckpointRepository checkpoints})
      : _checkpoints = checkpoints;

  final CheckpointRepository _checkpoints;

  Future<RuntimeTask?> recover(RuntimeTask task) async {
    final checkpoint = await _checkpoints.latestForTask(task.task.id.value);
    if (checkpoint == null) return null;
    final recovered = task.copy();
    recovered.state = _stateFromString(checkpoint.state);
    recovered.attempt = checkpoint.attempt;
    return recovered;
  }

  RuntimeState _stateFromString(String value) {
    switch (value) {
      case 'READY':
        return RuntimeState.ready;
      case 'RUNNING':
        return RuntimeState.running;
      case 'PAUSED':
        return RuntimeState.paused;
      case 'WAITING_APPROVAL':
        return RuntimeState.waitingApproval;
      default:
        return RuntimeState.recovering;
    }
  }
}
