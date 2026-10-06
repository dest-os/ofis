import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/live_operations/in_memory_live_operations_repository.dart';
import 'package:dest_os_ares/application/live_operations/live_operations_service.dart';
import 'package:dest_os_ares/domain/live_operations/live_operation.dart';
import 'package:dest_os_ares/domain/live_operations/live_operation_status.dart';

void main() {
  test('canlı operasyon yayınlanır ve snapshot içinde görünür', () async {
    final service = LiveOperationsService(
      InMemoryLiveOperationsRepository(),
    );

    await service.publish(
      LiveOperation(
        id: 'op-1',
        title: 'Test operasyonu',
        status: LiveOperationStatus.running,
        progress: 0.25,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final snapshot = await service.snapshot();

    expect(snapshot.operations, hasLength(1));
    expect(snapshot.runningCount, 1);
    expect(snapshot.operations.single.progress, 0.25);
  });

  test('ilerleme 0 ile 1 arasında güvenli tutulur', () async {
    final repository = InMemoryLiveOperationsRepository();
    final service = LiveOperationsService(repository);

    await service.publish(
      LiveOperation(
        id: 'op-2',
        title: 'Güvenlik testi',
        status: LiveOperationStatus.running,
        progress: 5.0,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final item = await repository.getById('op-2');

    expect(item?.progress, 1.0);
  });

  test('öncelikli operasyonlar önce gelir', () async {
    final service = LiveOperationsService(
      InMemoryLiveOperationsRepository(),
    );

    await service.publish(
      LiveOperation(
        id: 'low',
        title: 'Düşük',
        status: LiveOperationStatus.queued,
        progress: 0,
        updatedAt: DateTime.utc(2026, 1, 1),
        priority: 1,
      ),
    );
    await service.publish(
      LiveOperation(
        id: 'high',
        title: 'Yüksek',
        status: LiveOperationStatus.running,
        progress: 0.5,
        updatedAt: DateTime.utc(2026, 1, 1),
        priority: 10,
      ),
    );

    final snapshot = await service.snapshot();

    expect(snapshot.operations.first.id, 'high');
  });
}
