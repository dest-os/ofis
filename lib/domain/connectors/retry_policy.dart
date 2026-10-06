class ConnectorRetryPolicy {
  const ConnectorRetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 250),
  });

  final int maxAttempts;
  final Duration baseDelay;
}
