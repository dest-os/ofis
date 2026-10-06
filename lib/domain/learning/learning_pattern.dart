class LearningPattern {
  final String id;
  final String name;
  final bool positive;
  final int occurrences;
  final double confidence;
  final String description;
  final DateTime updatedAt;

  const LearningPattern({
    required this.id,
    required this.name,
    required this.positive,
    required this.occurrences,
    required this.confidence,
    required this.description,
    required this.updatedAt,
  });
}
