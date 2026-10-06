import '../workflows/workflow_trigger.dart';

class AutomationRule {
  final String id;
  final String name;
  final WorkflowTrigger trigger;
  final String workflowId;
  final bool enabled;
  final bool requiresApproval;

  const AutomationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.workflowId,
    this.enabled = true,
    this.requiresApproval = false,
  });
}
