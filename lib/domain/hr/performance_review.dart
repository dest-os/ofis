class PerformanceReview {
  final String id;
  final String employeeId;
  final DateTime reviewedAt;
  final double qualityScore;
  final double reliabilityScore;
  final double speedScore;
  final String summary;
  final bool recommendedForPromotion;
  final bool recommendedForSuspension;

  const PerformanceReview({
    required this.id,
    required this.employeeId,
    required this.reviewedAt,
    required this.qualityScore,
    required this.reliabilityScore,
    required this.speedScore,
    required this.summary,
    this.recommendedForPromotion = false,
    this.recommendedForSuspension = false,
  })  : assert(qualityScore >= 0 && qualityScore <= 1),
        assert(reliabilityScore >= 0 && reliabilityScore <= 1),
        assert(speedScore >= 0 && speedScore <= 1);

  double get overallScore =>
      (qualityScore + reliabilityScore + speedScore) / 3;
}
