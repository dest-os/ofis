import 'workflow_status.dart';
import 'workflow_trigger.dart';
import 'workflow_step.dart';

class WorkflowDefinition {
  final String id;
  final String name;
  final String description;
  final WorkflowStatus status;
  final WorkflowTrigger trigger;
  final List<WorkflowStep> steps;

  const WorkflowDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.status = WorkflowStatus.draft,
    required this.trigger,
    this.steps = const [],
  });
}
