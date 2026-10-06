import '../../domain/automations/automation_rule.dart';

class AutomationDecision {
  final bool allowed;
  final bool waitingApproval;
  final String reason;

  const AutomationDecision({
    required this.allowed,
    required this.waitingApproval,
    required this.reason,
  });
}

class AutomationGuard {
  AutomationDecision evaluate(AutomationRule rule) {
    if (!rule.enabled) {
      return const AutomationDecision(
        allowed: false,
        waitingApproval: false,
        reason: 'Otomasyon devre dışı.',
      );
    }
    if (rule.requiresApproval) {
      return const AutomationDecision(
        allowed: false,
        waitingApproval: true,
        reason: 'Kullanıcı onayı gerekli.',
      );
    }
    return const AutomationDecision(
      allowed: true,
      waitingApproval: false,
      reason: 'Otomasyon çalıştırılabilir.',
    );
  }
}
