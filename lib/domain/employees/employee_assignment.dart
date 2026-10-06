class EmployeeAssignment {
  final String employeeId;
  final String taskId;
  final DateTime assignedAt;
  final bool active;

  const EmployeeAssignment({
    required this.employeeId,
    required this.taskId,
    required this.assignedAt,
    required this.active,
  });

  EmployeeAssignment close() => EmployeeAssignment(
        employeeId: employeeId,
        taskId: taskId,
        assignedAt: assignedAt,
        active: false,
      );
}
