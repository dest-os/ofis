class LearningRecommendation {
  final String id;
  final String targetType;
  final String targetId;
  final String action;
  final double confidence;
  final bool requiresReview;
  final String reason;

  const LearningRecommendation({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.action,
    required this.confidence,
    required this.requiresReview,
    required this.reason,
  });
}
