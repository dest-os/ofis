enum TaskContractResultStatus {
  accepted,
  rejected,
  needsRevision,
}

class TaskContractResult {
  const TaskContractResult({
    required this.status,
    required this.completedCriteria,
    required this.missingCriteria,
    this.notes,
  });

  final TaskContractResultStatus status;
  final List<String> completedCriteria;
  final List<String> missingCriteria;
  final String? notes;

  bool get accepted => status == TaskContractResultStatus.accepted;
}
