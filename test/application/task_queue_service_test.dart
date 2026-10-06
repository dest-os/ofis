import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/tasks/in_memory_task_repository.dart';
import 'package:dest_os_ares/application/tasks/task_queue_service.dart';
import 'package:dest_os_ares/domain/tasks/task.dart';

void main() {
  test('görev kuyruğu önceliğe göre sıralanır', () async {
    final repository = InMemoryTaskRepository();
    final service = TaskQueueService(repository);

    await repository.save(
      Task(
        id: 'low',
        title: 'Düşük',
        description: '',
        status: 'READY',
        priority: 'low',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await repository.save(
      Task(
        id: 'critical',
        title: 'Kritik',
        description: '',
        status: 'READY',
        priority: 'critical',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );

    final queue = await service.prioritizedQueue();

    expect(queue.first.id, 'critical');
    expect(queue.last.id, 'low');
  });
}
