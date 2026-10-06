import '../../domain/automation/automation_rule.dart';
import 'automation_guard.dart';

class TaskAutomationService {
  const TaskAutomationService(this.guard);

  final AutomationGuard guard;

  bool canStart(AutomationRule rule, {required bool approvalGranted}) =>
      guard.mayRun(rule, approvalGranted: approvalGranted);
}
