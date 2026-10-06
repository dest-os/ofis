class QuotaState {
  const QuotaState({
    required this.windowStartedAt,
    this.calls = 0,
    this.estimatedCost = 0,
  });

  final DateTime windowStartedAt;
  final int calls;
  final double estimatedCost;
}
