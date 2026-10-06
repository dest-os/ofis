import '../../domain/tasks/task.dart';

abstract interface class TaskRepository {
  Future<void> save(Task task);
  Future<Task?> getById(String taskId);
  Future<List<Task>> getAll();
  Future<void> remove(String taskId);
}
