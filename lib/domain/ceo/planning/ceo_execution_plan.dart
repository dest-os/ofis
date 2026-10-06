import '../../tasks/task_priority.dart';
import 'plan_step.dart';

class CeoExecutionPlan {
  CeoExecutionPlan({
    required this.id,
    required this.goal,
    required this.priority,
    required List<PlanStep> steps,
    DateTime? createdAt,
    this.requiresApproval = false,
  })  : steps = List<PlanStep>.unmodifiable(steps),
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  final String id;
  final String goal;
  final TaskPriority priority;
  final List<PlanStep> steps;
  final DateTime createdAt;
  final bool requiresApproval;

  bool get isEmpty => steps.isEmpty;
}
