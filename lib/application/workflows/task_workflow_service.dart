import '../../domain/workflows/workflow_definition.dart';
import 'workflow_service.dart';

class TaskWorkflowService {
  const TaskWorkflowService(this.workflowService);

  final WorkflowService workflowService;

  bool readyToAdvance(WorkflowDefinition workflow, Set<String> completedStepIds) =>
      workflowService.dependenciesSatisfied(workflow, completedStepIds);
}
