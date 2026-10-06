import '../../domain/workflows/workflow_definition.dart';

class WorkflowValidationResult {
  final bool valid;
  final List<String> errors;
  const WorkflowValidationResult(this.valid, this.errors);
}

class WorkflowValidator {
  WorkflowValidationResult validate(WorkflowDefinition workflow) {
    final errors = <String>[];
    final ids = workflow.steps.map((s) => s.id).toSet();
    if (workflow.name.trim().isEmpty) errors.add('Workflow adı boş olamaz.');
    for (final step in workflow.steps) {
      for (final dependency in step.dependsOn) {
        if (!ids.contains(dependency)) {
          errors.add('Eksik bağımlılık: $dependency');
        }
        if (dependency == step.id) {
          errors.add('Adım kendisine bağımlı olamaz: ${step.id}');
        }
      }
    }
    return WorkflowValidationResult(errors.isEmpty, errors);
  }
}
