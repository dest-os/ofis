/// Kod üretim sürecinin değişmez planını temsil eder.
class GenerationPlan {
  /// Creates a generation plan with an immutable step list.
  GenerationPlan({
    required this.projectName,
    required List<GenerationStep> steps,
  }) : steps = List.unmodifiable(steps);

  /// Name of the project being generated.
  final String projectName;

  /// Ordered steps that make up the generation process.
  final List<GenerationStep> steps;

  /// Returns a copy with the supplied fields replaced.
  GenerationPlan copyWith({
    String? projectName,
    List<GenerationStep>? steps,
  }) {
    return GenerationPlan(
      projectName: projectName ?? this.projectName,
      steps: steps ?? this.steps,
    );
  }
}

/// Kod üretim planındaki tek bir adımı temsil eder.
class GenerationStep {
  /// Creates an immutable generation step.
  const GenerationStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.required,
  });

  /// Stable identifier of the step.
  final String id;

  /// Human-readable step name.
  final String name;

  /// Short explanation of what the step does.
  final String description;

  /// Position of the step in the plan.
  final int order;

  /// Whether the step is mandatory for a successful generation.
  final bool required;

  /// Returns a copy with the supplied fields replaced.
  GenerationStep copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? required,
  }) {
    return GenerationStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      required: required ?? this.required,
    );
  }
}
