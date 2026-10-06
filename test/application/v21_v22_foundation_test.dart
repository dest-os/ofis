import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/ai_center/ai_center_service.dart';
import 'package:dest_os_ares/application/automation/automation_guard.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/ai_center/ai_center_category.dart';
import 'package:dest_os_ares/domain/ai_center/ai_provider_profile.dart';
import 'package:dest_os_ares/domain/automation/automation_rule.dart';
import 'package:dest_os_ares/domain/automation/automation_trigger.dart';

void main() {
  test('ücretli ve bilinmeyen AI onay gerektirir', () {
    const service = AiCenterService();
    const paid = AiProviderProfile(provider: 'X', model: 'Y', address: 'https://example.invalid', category: AiCenterCategory.paid, capabilities: [], verified: true);
    const unknown = AiProviderProfile(provider: 'X', model: 'Y', address: '', category: AiCenterCategory.unknown, capabilities: [], verified: false);
    expect(service.requiresApproval(paid), isTrue);
    expect(service.requiresApproval(unknown), isTrue);
    expect(service.toCostClass(paid), AiCostClass.paid);
  });

  test('onay gerektiren otomasyon onaysız çalışmaz', () {
    const guard = AutomationGuard();
    const rule = AutomationRule(id: 'a1', name: 'test', trigger: AutomationTrigger.event, enabled: true, requiresApproval: true);
    expect(guard.mayRun(rule, approvalGranted: false), isFalse);
    expect(guard.mayRun(rule, approvalGranted: true), isTrue);
  });
}
