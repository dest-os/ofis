enum WorkflowTriggerType { manual, taskCreated, event, schedule, condition }

class WorkflowTrigger {
  final WorkflowTriggerType type;
  final String? eventType;
  final String? schedule;
  final String? condition;

  const WorkflowTrigger({
    required this.type,
    this.eventType,
    this.schedule,
    this.condition,
  });
}
