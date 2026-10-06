import 'package:flutter/material.dart';

import '../../application/tasks/in_memory_task_repository.dart';
import '../../application/tasks/task_queue_service.dart';
import '../../application/tasks/task_role_service.dart';
import '../../domain/tasks/task.dart';
import '../../core/ids/ares_id.dart';
import '../../domain/tasks/task_role.dart';

class TaskRoleScreen extends StatefulWidget {
  const TaskRoleScreen({super.key});

  @override
  State<TaskRoleScreen> createState() => _TaskRoleScreenState();
}

class _TaskRoleScreenState extends State<TaskRoleScreen> {
  final _repository = InMemoryTaskRepository();
  late final TaskRoleService _roleService = TaskRoleService(_repository);
  late final TaskQueueService _queueService = TaskQueueService(_repository);

  List<Task> _tasks = const [];

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    await _repository.save(
      Task(
        id: AresId('task-v10-demo'),
        title: 'V10 görev ve rol altyapısını doğrula',
        description: 'Görev önceliği ve rol atama akışını kontrol et.',
        status: 'READY',
        priority: 'high',
        createdAt: DateTime.now().toUtc(),
      ),
    );

    await _roleService.assign(
      taskId: 'task-v10-demo',
      agentId: 'ares-agent-001',
      role: TaskRole.executor,
      assignmentId: 'assignment-v10-001',
    );

    await _refresh();
  }

  Future<void> _refresh() async {
    final tasks = await _queueService.prioritizedQueue();
    if (!mounted) return;
    setState(() => _tasks = tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARES • Görev ve Roller'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final assignments = _roleService.assignmentsFor(task.id.value);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Durum: ${task.status}'),
                  Text('Öncelik: ${task.priority}'),
                  const SizedBox(height: 12),
                  ...assignments.map(
                    (assignment) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(assignment.agentId),
                      subtitle: Text(assignment.role.value),
                      trailing: Icon(
                        assignment.accepted
                            ? Icons.check_circle
                            : Icons.pending_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
