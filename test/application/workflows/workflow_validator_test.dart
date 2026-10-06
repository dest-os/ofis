import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/domain/workflows/workflow_definition.dart';
import 'package:dest_os_ares/domain/workflows/workflow_step.dart';
import 'package:dest_os_ares/domain/workflows/workflow_trigger.dart';
import 'package:dest_os_ares/application/workflows/workflow_validator.dart';

void main() {
  test('geçerli workflow kabul edilir', () {
    final workflow = WorkflowDefinition(
      id: 'wf-1',
      name: 'Test',
      trigger: const WorkflowTrigger(type: WorkflowTriggerType.manual),
      steps: const [WorkflowStep(id: 'a', name: 'A', taskType: 'test')],
    );
    expect(WorkflowValidator().validate(workflow).valid, isTrue);
  });

  test('eksik bağımlılık reddedilir', () {
    final workflow = WorkflowDefinition(
      id: 'wf-2',
      name: 'Test',
      trigger: const WorkflowTrigger(type: WorkflowTriggerType.manual),
      steps: const [WorkflowStep(id: 'a', name: 'A', taskType: 'test', dependsOn: ['x'])],
    );
    expect(WorkflowValidator().validate(workflow).valid, isFalse);
  });
}
