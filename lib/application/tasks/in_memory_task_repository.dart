import '../../domain/tasks/task.dart';
import 'task_repository.dart';

class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _items = <String, Task>{};

  @override
  Future<List<Task>> getAll() async {
    return List<Task>.unmodifiable(_items.values);
  }

  @override
  Future<Task?> getById(String taskId) async => _items[taskId];

  @override
  Future<void> remove(String taskId) async {
    _items.remove(taskId);
  }

  @override
  Future<void> save(Task task) async {
    _items[task.id.value] = task;
  }
}
