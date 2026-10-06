import '../../../domain/ceo/planning/ceo_execution_plan.dart';

class PlanValidationResult {
  const PlanValidationResult({required this.valid, this.errors = const <String>[]});
  final bool valid;
  final List<String> errors;
}

class PlanValidator {
  const PlanValidator();

  PlanValidationResult validate(CeoExecutionPlan plan) {
    final errors = <String>[];
    final ids = <String>{};
    for (final step in plan.steps) {
      if (!ids.add(step.id)) errors.add('Tekrarlanan adım: ${step.id}');
      if (step.title.trim().isEmpty) errors.add('Başlıksız adım: ${step.id}');
      for (final dependency in step.dependencies) {
        if (dependency == step.id) errors.add('Adım kendisine bağımlı: ${step.id}');
      }
    }
    for (final step in plan.steps) {
      for (final dependency in step.dependencies) {
        if (!ids.contains(dependency)) {
          errors.add('Bulunamayan bağımlılık: $dependency');
        }
      }
    }
    return PlanValidationResult(valid: errors.isEmpty, errors: errors);
  }
}
