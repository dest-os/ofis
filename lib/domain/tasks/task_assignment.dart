import 'task_role.dart';

class TaskAssignment {
  const TaskAssignment({
    required this.id,
    required this.taskId,
    required this.agentId,
    required this.role,
    required this.assignedAt,
    this.accepted = false,
  });

  final String id;
  final String taskId;
  final String agentId;
  final TaskRole role;
  final DateTime assignedAt;
  final bool accepted;

  TaskAssignment copyWith({
    String? id,
    String? taskId,
    String? agentId,
    TaskRole? role,
    DateTime? assignedAt,
    bool? accepted,
  }) {
    return TaskAssignment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      agentId: agentId ?? this.agentId,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      accepted: accepted ?? this.accepted,
    );
  }
}
