class RuntimeHealth {
  const RuntimeHealth({
    required this.healthy,
    required this.message,
    required this.checkedAt,
  });

  final bool healthy;
  final String message;
  final DateTime checkedAt;
}
