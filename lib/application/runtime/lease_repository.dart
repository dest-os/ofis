import '../../domain/runtime/lease.dart';

abstract interface class LeaseRepository {
  Future<void> save(RuntimeLease lease);
  Future<RuntimeLease?> findByTaskId(String taskId);
  Future<void> delete(String leaseId);
  Future<List<RuntimeLease>> all();
}
