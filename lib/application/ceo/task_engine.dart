import '../../core/ids/ares_id.dart';
import '../../domain/ceo/ceo_plan.dart';
import '../../domain/tasks/task.dart';
import '../../domain/tasks/task_status.dart';
import '../tasks/task_repository.dart';

class TaskEngine {
  TaskEngine(this._repository);

  final TaskRepository _repository;

  Future<Task> materializePlanTask({
    required CeoPlan plan,
    required String taskId,
  }) async {
    if (!plan.taskIds.contains(taskId)) {
      throw StateError('Görev planın içinde bulunmuyor: $taskId');
    }

    final existing = await _repository.getById(taskId);
    if (existing != null) {
      return existing;
    }

    final task = Task(
      id: AresId(taskId),
      title: plan.goal,
      description: 'CEO planından oluşturuldu.',
      status: TaskStatus.received.name,
      priority: plan.priority.name,
      createdAt: DateTime.now().toUtc(),
    );

    await _repository.save(task);
    return task;
  }

  Future<Task> transition(
    String taskId,
    TaskStatus nextStatus,
  ) async {
    final current = await _repository.getById(taskId);
    if (current == null) {
      throw StateError('Görev bulunamadı: $taskId');
    }

    final updated = current.copyWith(status: nextStatus.name);
    await _repository.save(updated);
    return updated;
  }
}
