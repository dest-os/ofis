class LearningGuardResult {
  final bool allowed;
  final bool requiresReview;
  final String reason;

  const LearningGuardResult({
    required this.allowed,
    required this.requiresReview,
    required this.reason,
  });
}
