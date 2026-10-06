import 'package:flutter_test/flutter_test.dart';
import 'package:ares/domain/ceo/ceo_intent.dart';
import 'package:ares/domain/tasks/task_priority.dart';
import 'package:ares/application/ceo/planning/ceo_planning_engine.dart';

void main() {
  test('CEO planı hedef ve öncelik ile oluşturur', () {
    final engine = CeoPlanningEngine();
    final plan = engine.createPlan(
      planId: 'plan-1',
      intent: const CeoIntent(
        type: CeoIntentType.createTask,
        rawText: 'kritik görevi hazırla',
        goal: 'Görevi hazırla',
        priority: 'critical',
      ),
    );

    expect(plan.goal, 'Görevi hazırla');
    expect(plan.priority, TaskPriority.critical);
    expect(plan.requiresApproval, isTrue);
    expect(plan.steps, hasLength(1));
  });
}
