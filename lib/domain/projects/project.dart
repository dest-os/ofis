import 'project_status.dart';

class Project {
  final String id;
  final String name;
  final String goal;
  final String scope;
  final ProjectStatus status;
  final String? leadEmployeeId;
  final List<String> departmentIds;
  final List<String> teamEmployeeIds;
  final List<String> taskIds;
  final List<String> milestoneIds;
  final List<String> riskIds;
  final List<String> decisionIds;
  final String memoryNamespace;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.goal,
    required this.scope,
    required this.status,
    required this.leadEmployeeId,
    required this.departmentIds,
    required this.teamEmployeeIds,
    required this.taskIds,
    required this.milestoneIds,
    required this.riskIds,
    required this.decisionIds,
    required this.memoryNamespace,
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    String? name,
    String? goal,
    String? scope,
    ProjectStatus? status,
    String? leadEmployeeId,
    List<String>? departmentIds,
    List<String>? teamEmployeeIds,
    List<String>? taskIds,
    List<String>? milestoneIds,
    List<String>? riskIds,
    List<String>? decisionIds,
    String? memoryNamespace,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      scope: scope ?? this.scope,
      status: status ?? this.status,
      leadEmployeeId: leadEmployeeId ?? this.leadEmployeeId,
      departmentIds: List.unmodifiable(departmentIds ?? this.departmentIds),
      teamEmployeeIds: List.unmodifiable(teamEmployeeIds ?? this.teamEmployeeIds),
      taskIds: List.unmodifiable(taskIds ?? this.taskIds),
      milestoneIds: List.unmodifiable(milestoneIds ?? this.milestoneIds),
      riskIds: List.unmodifiable(riskIds ?? this.riskIds),
      decisionIds: List.unmodifiable(decisionIds ?? this.decisionIds),
      memoryNamespace: memoryNamespace ?? this.memoryNamespace,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
