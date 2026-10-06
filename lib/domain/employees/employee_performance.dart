class EmployeePerformance {
  final String employeeId;
  final int completedTasks;
  final int failedTasks;
  final double qualityScore;
  final double reliabilityScore;
  final double speedScore;

  const EmployeePerformance({
    required this.employeeId,
    this.completedTasks = 0,
    this.failedTasks = 0,
    this.qualityScore = 0,
    this.reliabilityScore = 0,
    this.speedScore = 0,
  });

  double get successRate {
    final total = completedTasks + failedTasks;
    if (total == 0) return 0;
    return completedTasks / total;
  }
}
