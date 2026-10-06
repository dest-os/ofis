class TimeoutGuard {
  const TimeoutGuard();

  Future<T> run<T>(
    Future<T> future, {
    required Duration timeout,
  }) {
    return future.timeout(timeout);
  }
}
