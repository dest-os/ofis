import '../../domain/runtime/runtime_task.dart';
import '../../domain/runtime/runtime_state.dart';
import 'checkpoint_repository.dart';

class RestartRecoveryService {
  RestartRecoveryService({required CheckpointRepository checkpoints})
      : _checkpoints = checkpoints;

  final CheckpointRepository _checkpoints;

  Future<List<RuntimeTask>> findRecoverable(
    List<RuntimeTask> knownTasks,
  ) async {
    final recoverable = <RuntimeTask>[];
    for (final task in knownTasks) {
      final checkpoint = await _checkpoints.latestForTask(task.task.id.value);
      if (checkpoint == null) continue;

      final state = _state(checkpoint.state);
      if (state == RuntimeState.running ||
          state == RuntimeState.paused ||
          state == RuntimeState.waitingApproval ||
          state == RuntimeState.recovering) {
        final copy = task.copy();
        copy.state = RuntimeState.recovering;
        copy.attempt = checkpoint.attempt;
        recoverable.add(copy);
      }
    }
    return recoverable;
  }

  RuntimeState _state(String value) {
    for (final state in RuntimeState.values) {
      if (state.value == value) return state;
    }
    return RuntimeState.recovering;
  }
}
