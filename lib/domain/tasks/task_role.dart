enum TaskRole {
  owner,
  planner,
  executor,
  reviewer,
  securityAuditor,
  tester,
  recoveryManager,
  observer,
}

extension TaskRoleX on TaskRole {
  String get value => name.toUpperCase();
}
