class WorkflowStep {
  final String id;
  final String name;
  final String taskType;
  final List<String> dependsOn;
  final bool requiresApproval;

  const WorkflowStep({
    required this.id,
    required this.name,
    required this.taskType,
    this.dependsOn = const [],
    this.requiresApproval = false,
  });
}
