import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/ceo/task_engine.dart';
import 'package:dest_os_ares/application/tasks/in_memory_task_repository.dart';
import 'package:dest_os_ares/domain/ceo/ceo_plan.dart';
import 'package:dest_os_ares/domain/tasks/task_priority.dart';
import 'package:dest_os_ares/domain/tasks/task_status.dart';

void main() {
  test('CEO planından görev oluşturulabilir', () async {
    final repository = InMemoryTaskRepository();
    final engine = TaskEngine(repository);

    final plan = CeoPlan(
      id: 'plan-1',
      goal: 'Test görevi',
      taskIds: const ['task-1'],
      priority: TaskPriority.normal,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final task = await engine.materializePlanTask(
      plan: plan,
      taskId: 'task-1',
    );

    expect(task.id, 'task-1');
    expect(task.status, TaskStatus.received.name);
  });
}
