import '../../domain/automation/automation_rule.dart';

class AutomationGuard {
  bool mayRun(AutomationRule rule, {required bool approvalGranted}) {
    if (!rule.enabled) return false;
    if (rule.requiresApproval && !approvalGranted) return false;
    return true;
  }
}
