import '../../../domain/ceo/ceo_intent.dart';
import '../../../domain/ceo/planning/ceo_execution_plan.dart';
import '../../../domain/ceo/planning/plan_step.dart';
import '../../../domain/tasks/task_priority.dart';

class CeoPlanningEngine {
  CeoExecutionPlan createPlan({
    required String planId,
    required CeoIntent intent,
    List<PlanStep> steps = const <PlanStep>[],
  }) {
    final goal = (intent.goal ?? intent.rawText).trim();
    if (goal.isEmpty) {
      throw ArgumentError('Plan hedefi boş olamaz.');
    }

    final normalizedSteps = steps.isEmpty
        ? <PlanStep>[
            PlanStep(
              id: '$planId-step-1',
              title: goal,
              description: intent.rawText,
              acceptanceCriteria: const <String>['Görev sonucu doğrulanabilir olmalı.'],
            ),
          ]
        : steps;

    return CeoExecutionPlan(
      id: planId,
      goal: goal,
      priority: _priority(intent.priority),
      steps: normalizedSteps,
      requiresApproval: intent.priority.toLowerCase() == 'critical',
    );
  }

  TaskPriority _priority(String value) {
    switch (value.toLowerCase()) {
      case 'critical':
        return TaskPriority.critical;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.normal;
    }
  }
}
