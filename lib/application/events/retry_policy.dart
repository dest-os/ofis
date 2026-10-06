class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelayMilliseconds = 100,
  });

  final int maxRetries;
  final int baseDelayMilliseconds;

  bool canRetry(int retryCount) => retryCount < maxRetries;

  int delayMilliseconds(int retryCount) {
    final exponent = retryCount.clamp(0, maxRetries);
    return baseDelayMilliseconds * (1 << exponent);
  }
}
