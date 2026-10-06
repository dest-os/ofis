class QuotaPolicy {
  const QuotaPolicy({
    required this.maxCalls,
    this.window = const Duration(hours: 1),
    this.maxEstimatedCost = 0,
  });

  final int maxCalls;
  final Duration window;
  final double maxEstimatedCost;
}
