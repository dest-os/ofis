class PlanStep {
  const PlanStep({
    required this.id,
    required this.title,
    required this.description,
    this.requiredSkills = const <String>[],
    this.dependencies = const <String>[],
    this.acceptanceCriteria = const <String>[],
    this.parallelizable = true,
  });

  final String id;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final List<String> dependencies;
  final List<String> acceptanceCriteria;
  final bool parallelizable;
}
