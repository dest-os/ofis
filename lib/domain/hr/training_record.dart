class TrainingRecord {
  final String id;
  final String employeeId;
  final String skillId;
  final String title;
  final double completion;
  final bool passed;
  final DateTime startedAt;
  final DateTime? completedAt;

  const TrainingRecord({
    required this.id,
    required this.employeeId,
    required this.skillId,
    required this.title,
    required this.completion,
    required this.passed,
    required this.startedAt,
    this.completedAt,
  }) : assert(completion >= 0 && completion <= 1);

  TrainingRecord update({double? completion, bool? passed, DateTime? completedAt}) {
    return TrainingRecord(
      id: id,
      employeeId: employeeId,
      skillId: skillId,
      title: title,
      completion: completion ?? this.completion,
      passed: passed ?? this.passed,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
