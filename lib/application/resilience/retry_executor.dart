class RetryExecutor {
  const RetryExecutor({this.defaultDelay = const Duration(milliseconds: 200)});

  final Duration defaultDelay;

  Future<T> run<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    Duration? delay,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (_) {
        if (attempt >= maxRetries) rethrow;
        attempt++;
        await Future<void>.delayed(delay ?? defaultDelay);
      }
    }
  }
}
