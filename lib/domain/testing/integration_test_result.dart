/// Status of a runtime integration check.
enum IntegrationTestStatus {
  /// The check passed.
  passed,

  /// The check failed.
  failed,
}

/// Result of one integration check.
class IntegrationTestResult {
  /// Creates an immutable integration test result.
  const IntegrationTestResult({
    required this.testId,
    required this.status,
    required this.message,
    required this.completedAt,
  });

  /// Stable test identifier.
  final String testId;

  /// Check status.
  final IntegrationTestStatus status;

  /// Human-readable result message.
  final String message;

  /// Completion timestamp.
  final DateTime completedAt;

  /// Whether the check passed.
  bool get passed => status == IntegrationTestStatus.passed;
}
