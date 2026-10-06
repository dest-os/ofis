import '../../domain/automations/automation_rule.dart';
import 'automation_guard.dart';

class AutomationService {
  final AutomationGuard guard;
  AutomationService({AutomationGuard? guard}) : guard = guard ?? AutomationGuard();

  AutomationDecision evaluate(AutomationRule rule) => guard.evaluate(rule);
}
