import '../../domain/runtime/lease.dart';
import 'lease_repository.dart';

class LeaseService {
  LeaseService({
    required LeaseRepository repository,
    this.leaseDuration = const Duration(seconds: 30),
  }) : _repository = repository;

  final LeaseRepository _repository;
  final Duration leaseDuration;

  Future<RuntimeLease> acquire({
    required String taskId,
    required String ownerId,
  }) async {
    final now = DateTime.now();
    final existing = await _repository.findByTaskId(taskId);
    if (existing != null && !existing.isExpired(now)) {
      throw StateError('Görev için aktif bir çalışma kilidi zaten var.');
    }

    final lease = RuntimeLease(
      id: '$taskId-$ownerId-${now.microsecondsSinceEpoch}',
      taskId: taskId,
      ownerId: ownerId,
      acquiredAt: now,
      expiresAt: now.add(leaseDuration),
    );
    await _repository.save(lease);
    return lease;
  }

  Future<bool> heartbeat(String leaseId) async {
    final leases = await _repository.all();
    RuntimeLease? lease;
    for (final item in leases) {
      if (item.id == leaseId) {
        lease = item;
        break;
      }
    }
    if (lease == null) return false;

    final now = DateTime.now();
    if (lease.isExpired(now)) return false;
    lease.heartbeat(now: now, extension: leaseDuration);
    await _repository.save(lease);
    return true;
  }

  Future<void> release(String leaseId) => _repository.delete(leaseId);
}
