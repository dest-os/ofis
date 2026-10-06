import '../../domain/runtime/lease.dart';
import 'lease_repository.dart';

class InMemoryLeaseRepository implements LeaseRepository {
  final Map<String, RuntimeLease> _items = <String, RuntimeLease>{};

  @override
  Future<void> save(RuntimeLease lease) async => _items[lease.id] = lease;

  @override
  Future<RuntimeLease?> findByTaskId(String taskId) async {
    for (final lease in _items.values) {
      if (lease.taskId == taskId) return lease;
    }
    return null;
  }

  @override
  Future<void> delete(String leaseId) async => _items.remove(leaseId);

  @override
  Future<List<RuntimeLease>> all() async => List.unmodifiable(_items.values);
}
