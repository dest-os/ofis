enum RuntimeResultStatus { success, waitingApproval, paused, failed, cancelled }

class RuntimeResult {
  const RuntimeResult({
    required this.status,
    this.output,
    this.error,
    this.metadata = const <String, Object?>{},
  });

  final RuntimeResultStatus status;
  final Object? output;
  final String? error;
  final Map<String, Object?> metadata;

  bool get isSuccess => status == RuntimeResultStatus.success;
}
