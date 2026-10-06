class LearningBenchmarkService {
  const LearningBenchmarkService();

  double compare({required double baseline, required double candidate}) {
    if (baseline == 0) return candidate == 0 ? 0 : 1;
    return (candidate - baseline) / baseline;
  }
}
