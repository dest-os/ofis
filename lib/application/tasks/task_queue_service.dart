import '../../domain/tasks/task.dart';
import '../../domain/tasks/task_priority.dart';
import 'task_repository.dart';

class TaskQueueService {
  TaskQueueService(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> prioritizedQueue() async {
    final tasks = await _repository.getAll();

    tasks.sort((a, b) {
      final priorityCompare = _priorityOf(b).weight.compareTo(
            _priorityOf(a).weight,
          );
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return List<Task>.unmodifiable(tasks);
  }

  TaskPriority _priorityOf(Task task) {
    final value = task.priority.toLowerCase();

    switch (value) {
      case 'critical':
        return TaskPriority.critical;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.normal;
    }
  }
}
