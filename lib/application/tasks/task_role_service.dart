import '../../domain/tasks/task_assignment.dart';
import '../../domain/tasks/task_role.dart';
import 'task_repository.dart';

class TaskRoleService {
  TaskRoleService(this._taskRepository);

  final TaskRepository _taskRepository;
  final Map<String, List<TaskAssignment>> _assignments =
      <String, List<TaskAssignment>>{};

  Future<TaskAssignment> assign({
    required String taskId,
    required String agentId,
    required TaskRole role,
    required String assignmentId,
  }) async {
    final task = await _taskRepository.getById(taskId);
    if (task == null) {
      throw StateError('Görev bulunamadı: $taskId');
    }

    final current = _assignments.putIfAbsent(
      taskId,
      () => <TaskAssignment>[],
    );

    final duplicate = current.any(
      (item) => item.agentId == agentId && item.role == role,
    );
    if (duplicate) {
      throw StateError('Bu ajan bu görev rolüne zaten atanmış.');
    }

    final assignment = TaskAssignment(
      id: assignmentId,
      taskId: taskId,
      agentId: agentId,
      role: role,
      assignedAt: DateTime.now().toUtc(),
    );

    current.add(assignment);
    return assignment;
  }

  List<TaskAssignment> assignmentsFor(String taskId) {
    return List<TaskAssignment>.unmodifiable(
      _assignments[taskId] ?? const <TaskAssignment>[],
    );
  }

  bool hasRole(String taskId, TaskRole role) {
    return (_assignments[taskId] ?? const <TaskAssignment>[])
        .any((item) => item.role == role);
  }

  Future<void> accept(String taskId, String assignmentId) async {
    final items = _assignments[taskId];
    if (items == null) {
      throw StateError('Görev ataması bulunamadı.');
    }

    final index = items.indexWhere((item) => item.id == assignmentId);
    if (index < 0) {
      throw StateError('Atama bulunamadı: $assignmentId');
    }

    items[index] = items[index].copyWith(accepted: true);
  }
}
