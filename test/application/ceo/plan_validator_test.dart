import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/ceo/planning/plan_validator.dart';
import 'package:dest_os_ares/domain/ceo/planning/ceo_execution_plan.dart';
import 'package:dest_os_ares/domain/ceo/planning/plan_step.dart';
import 'package:dest_os_ares/domain/tasks/task_priority.dart';

void main() {
  test('geçerli bağımlılıkları kabul eder', () {
    final plan = CeoExecutionPlan(
      id: 'p',
      goal: 'hedef',
      priority: TaskPriority.normal,
      steps: const <PlanStep>[
        PlanStep(id: 'a', title: 'A', description: 'A'),
        PlanStep(id: 'b', title: 'B', description: 'B', dependencies: <String>['a']),
      ],
    );
    expect(const PlanValidator().validate(plan).valid, isTrue);
  });

  test('olmayan bağımlılığı reddeder', () {
    final plan = CeoExecutionPlan(
      id: 'p',
      goal: 'hedef',
      priority: TaskPriority.normal,
      steps: const <PlanStep>[
        PlanStep(id: 'b', title: 'B', description: 'B', dependencies: <String>['a']),
      ],
    );
    expect(const PlanValidator().validate(plan).valid, isFalse);
  });
}
