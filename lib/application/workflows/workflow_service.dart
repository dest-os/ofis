import '../../domain/workflows/workflow_definition.dart';

class WorkflowService {
  bool dependenciesSatisfied(WorkflowDefinition workflow, Set<String> completedStepIds) {
    for (final step in workflow.steps) {
      if (!step.dependsOn.every(completedStepIds.contains)) return false;
    }
    return true;
  }
}
