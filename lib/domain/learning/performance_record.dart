class PerformanceRecord {
  final String subjectId;
  final String subjectType;
  final int sampleCount;
  final double successRate;
  final double averageScore;
  final DateTime updatedAt;

  const PerformanceRecord({
    required this.subjectId,
    required this.subjectType,
    required this.sampleCount,
    required this.successRate,
    required this.averageScore,
    required this.updatedAt,
  });

  PerformanceRecord addSample({required bool success, required double score, DateTime? at}) {
    final nextCount = sampleCount + 1;
    return PerformanceRecord(
      subjectId: subjectId,
      subjectType: subjectType,
      sampleCount: nextCount,
      successRate: ((successRate * sampleCount) + (success ? 1 : 0)) / nextCount,
      averageScore: ((averageScore * sampleCount) + score) / nextCount,
      updatedAt: at ?? DateTime.now(),
    );
  }
}
