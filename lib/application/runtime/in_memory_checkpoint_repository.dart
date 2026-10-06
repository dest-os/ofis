import '../../domain/runtime/checkpoint.dart';
import 'checkpoint_repository.dart';

class InMemoryCheckpointRepository implements CheckpointRepository {
  final Map<String, RuntimeCheckpoint> _items = <String, RuntimeCheckpoint>{};

  @override
  Future<void> save(RuntimeCheckpoint checkpoint) async {
    _items[checkpoint.id] = checkpoint;
  }

  @override
  Future<RuntimeCheckpoint?> latestForTask(String taskId) async {
    final matches = _items.values.where((item) => item.taskId == taskId).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return matches.last;
  }

  @override
  Future<List<RuntimeCheckpoint>> all() async => List.unmodifiable(_items.values);
}
