enum CircuitState { closed, open, halfOpen }

class CircuitBreaker {
  CircuitBreaker({this.failureThreshold = 3});

  final int failureThreshold;
  int _failures = 0;
  CircuitState _state = CircuitState.closed;

  CircuitState get state => _state;

  bool get canExecute => _state != CircuitState.open;

  void recordSuccess() {
    _failures = 0;
    _state = CircuitState.closed;
  }

  void recordFailure() {
    _failures++;
    if (_failures >= failureThreshold) {
      _state = CircuitState.open;
    }
  }

  void reset() {
    _failures = 0;
    _state = CircuitState.closed;
  }

  void tryHalfOpen() {
    if (_state == CircuitState.open) {
      _state = CircuitState.halfOpen;
    }
  }
}
