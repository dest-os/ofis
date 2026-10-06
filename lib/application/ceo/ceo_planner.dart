import '../../domain/ceo/ceo_intent.dart';
import '../../domain/ceo/ceo_plan.dart';
import '../../domain/ceo/task_definition.dart';
import '../../domain/tasks/task_priority.dart';

class CeoPlanner {
  CeoPlan createPlan({
    required CeoIntent intent,
    required String planId,
    required String taskId,
  }) {
    final priority = _priority(intent.priority);

    final task = TaskDefinition(
      id: taskId,
      title: intent.goal ?? intent.rawText,
      description: intent.rawText,
      priority: priority,
      requiredCapabilities: List.unmodifiable(intent.requiredCapabilities),
      requiresApproval: priority == TaskPriority.critical,
    );

    return CeoPlan(
      id: planId,
      goal: task.title,
      taskIds: <String>[task.id],
      priority: priority,
      createdAt: DateTime.now().toUtc(),
      requiredCapabilities: List.unmodifiable(task.requiredCapabilities),
      requiresApproval: task.requiresApproval,
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
