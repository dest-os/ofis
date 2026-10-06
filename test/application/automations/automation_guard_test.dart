import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/domain/automations/automation_rule.dart';
import 'package:dest_os_ares/domain/workflows/workflow_trigger.dart';
import 'package:dest_os_ares/application/automations/automation_guard.dart';

void main() {
  test('onay gereken otomasyon beklemeye alınır', () {
    final rule = AutomationRule(
      id: 'a1',
      name: 'Onaylı',
      trigger: const WorkflowTrigger(type: WorkflowTriggerType.manual),
      workflowId: 'wf1',
      requiresApproval: true,
    );
    final result = AutomationGuard().evaluate(rule);
    expect(result.allowed, isFalse);
    expect(result.waitingApproval, isTrue);
  });
}
