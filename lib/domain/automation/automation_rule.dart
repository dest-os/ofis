import 'automation_trigger.dart';

class AutomationRule {
  const AutomationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.enabled,
    required this.requiresApproval,
  });

  final String id;
  final String name;
  final AutomationTrigger trigger;
  final bool enabled;
  final bool requiresApproval;
}
