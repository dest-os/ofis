import '../../domain/live_operations/live_operation.dart';
import 'live_operations_repository.dart';

class InMemoryLiveOperationsRepository
    implements LiveOperationsRepository {
  final Map<String, LiveOperation> _items = <String, LiveOperation>{};

  @override
  Future<LiveOperation?> getById(String operationId) async {
    return _items[operationId];
  }

  @override
  Future<List<LiveOperation>> getAll() async {
    return List<LiveOperation>.unmodifiable(_items.values);
  }

  @override
  Future<void> remove(String operationId) async {
    _items.remove(operationId);
  }

  @override
  Future<void> upsert(LiveOperation operation) async {
    _items[operation.id] = operation;
  }
}
