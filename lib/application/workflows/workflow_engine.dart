import '../../domain/workflows/workflow_definition.dart';
import '../../domain/workflows/workflow_step.dart';
import 'workflow_repository.dart';
import 'workflow_validator.dart';

class WorkflowEngine {
  final WorkflowRepository repository;
  final WorkflowValidator validator;

  WorkflowEngine({required this.repository, WorkflowValidator? validator})
      : validator = validator ?? WorkflowValidator();

  Future<List<WorkflowStep>> readySteps(WorkflowDefinition workflow, Set<String> completedStepIds) async {
    final validation = validator.validate(workflow);
    if (!validation.valid) throw StateError(validation.errors.join(' '));
    return workflow.steps
        .where((step) => !completedStepIds.contains(step.id))
        .where((step) => step.dependsOn.every(completedStepIds.contains))
        .toList(growable: false);
  }
}
