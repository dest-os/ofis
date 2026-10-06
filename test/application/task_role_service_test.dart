import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/tasks/in_memory_task_repository.dart';
import 'package:dest_os_ares/application/tasks/task_role_service.dart';
import 'package:dest_os_ares/domain/tasks/task.dart';
import 'package:dest_os_ares/domain/tasks/task_role.dart';

void main() {
  test('göreve ajan ve rol atanabilir', () async {
    final repository = InMemoryTaskRepository();
    final service = TaskRoleService(repository);

    await repository.save(
      Task(
        id: 'task-1',
        title: 'Test',
        description: 'Test görevi',
        status: 'READY',
        priority: 'normal',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final assignment = await service.assign(
      taskId: 'task-1',
      agentId: 'agent-1',
      role: TaskRole.reviewer,
      assignmentId: 'assignment-1',
    );

    expect(assignment.role, TaskRole.reviewer);
    expect(service.hasRole('task-1', TaskRole.reviewer), isTrue);
  });

  test('aynı ajan aynı role ikinci kez atanamaz', () async {
    final repository = InMemoryTaskRepository();
    final service = TaskRoleService(repository);

    await repository.save(
      Task(
        id: 'task-2',
        title: 'Test',
        description: 'Test görevi',
        status: 'READY',
        priority: 'normal',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await service.assign(
      taskId: 'task-2',
      agentId: 'agent-2',
      role: TaskRole.executor,
      assignmentId: 'assignment-1',
    );

    expect(
      () => service.assign(
        taskId: 'task-2',
        agentId: 'agent-2',
        role: TaskRole.executor,
        assignmentId: 'assignment-2',
      ),
      throwsStateError,
    );
  });
}
