import '../../domain/runtime/checkpoint.dart';

abstract interface class CheckpointRepository {
  Future<void> save(RuntimeCheckpoint checkpoint);
  Future<RuntimeCheckpoint?> latestForTask(String taskId);
  Future<List<RuntimeCheckpoint>> all();
}
