enum LiveOperationStatus {
  queued,
  running,
  waitingApproval,
  paused,
  blocked,
  completed,
  failed,
  cancelled,
}

extension LiveOperationStatusX on LiveOperationStatus {
  String get value => name.toUpperCase();

  bool get isActive =>
      this == LiveOperationStatus.queued ||
      this == LiveOperationStatus.running ||
      this == LiveOperationStatus.waitingApproval ||
      this == LiveOperationStatus.paused ||
      this == LiveOperationStatus.blocked;
}
