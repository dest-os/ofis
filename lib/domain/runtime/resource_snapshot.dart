class ResourceSnapshot {
  const ResourceSnapshot({
    required this.capturedAt,
    this.batteryPercent,
    this.isCharging,
    this.isNetworkAvailable,
    this.activeWorkers = 0,
  });

  final DateTime capturedAt;
  final int? batteryPercent;
  final bool? isCharging;
  final bool? isNetworkAvailable;
  final int activeWorkers;
}
