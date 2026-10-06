class RuntimeLease {
  RuntimeLease({
    required this.id,
    required this.taskId,
    required this.ownerId,
    required this.acquiredAt,
    required this.expiresAt,
  });

  final String id;
  final String taskId;
  final String ownerId;
  final DateTime acquiredAt;
  DateTime expiresAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  void heartbeat({required DateTime now, required Duration extension}) {
    expiresAt = now.add(extension);
  }
}
