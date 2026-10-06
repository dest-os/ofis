import '../../config/runtime_config.dart';
import '../../health/runtime_health_service.dart';
import '../../resilience/circuit_breaker.dart';
import '../../resilience/retry_executor.dart';
import '../../resilience/timeout_guard.dart';
import '../../../domain/runtime/runtime_command.dart';
import '../../../domain/runtime/runtime_mode.dart';
import '../../../domain/runtime/runtime_snapshot.dart';
import '../../../domain/runtime/runtime_status.dart';
import 'runtime_module_registry.dart';

class ProductionRuntime {
  ProductionRuntime({
    RuntimeConfig? config,
    RuntimeModuleRegistry? modules,
    RuntimeHealthService? health,
  })  : config = config ?? const RuntimeConfig(),
        modules = modules ?? RuntimeModuleRegistry(),
        health = health ?? RuntimeHealthService();

  final RuntimeConfig config;
  final RuntimeModuleRegistry modules;
  final RuntimeHealthService health;
  final RetryExecutor retry = const RetryExecutor();
  final TimeoutGuard timeout = const TimeoutGuard();
  final CircuitBreaker circuitBreaker = CircuitBreaker();

  RuntimeStatus _status = RuntimeStatus.stopped;
  RuntimeMode _mode = RuntimeMode.online;
  DateTime? _startedAt;
  DateTime? _lastHeartbeat;
  int _activeTasks = 0;
  int _activeAgents = 0;

  RuntimeStatus get status => _status;
  RuntimeMode get mode => _mode;

  RuntimeSnapshot snapshot() => RuntimeSnapshot(
        status: _status,
        mode: _mode,
        startedAt: _startedAt,
        lastHeartbeat: _lastHeartbeat,
        activeTasks: _activeTasks,
        activeAgents: _activeAgents,
      );

  Future<void> start() async {
    if (_status == RuntimeStatus.running || _status == RuntimeStatus.starting) {
      return;
    }
    _status = RuntimeStatus.starting;
    try {
      await timeout.run(
        retry.run(
          action: modules.startAll,
          maxRetries: config.maxRetryCount,
        ),
        timeout: config.startupTimeout,
      );
      _startedAt = DateTime.now();
      _lastHeartbeat = _startedAt;
      _mode = RuntimeMode.online;
      _status = RuntimeStatus.running;
      circuitBreaker.recordSuccess();
    } catch (_) {
      circuitBreaker.recordFailure();
      _status = RuntimeStatus.failed;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_status == RuntimeStatus.stopped || _status == RuntimeStatus.stopping) {
      return;
    }
    _status = RuntimeStatus.stopping;
    try {
      await timeout.run(
        modules.stopAll(),
        timeout: config.shutdownTimeout,
      );
    } finally {
      _status = RuntimeStatus.stopped;
      _activeTasks = 0;
      _activeAgents = 0;
    }
  }

  Future<void> execute(RuntimeCommand command) async {
    switch (command.type) {
      case RuntimeCommandType.start:
        await start();
        return;
      case RuntimeCommandType.stop:
        await stop();
        return;
      case RuntimeCommandType.pause:
        _status = RuntimeStatus.degraded;
        return;
      case RuntimeCommandType.resume:
        if (_status == RuntimeStatus.degraded) {
          _status = RuntimeStatus.running;
        }
        return;
      case RuntimeCommandType.recover:
        _mode = RuntimeMode.recovering;
        await start();
        return;
      case RuntimeCommandType.enterSafeMode:
        _mode = RuntimeMode.safeMode;
        _status = RuntimeStatus.degraded;
        return;
    }
  }

  void heartbeat({int activeTasks = 0, int activeAgents = 0}) {
    _lastHeartbeat = DateTime.now();
    _activeTasks = activeTasks;
    _activeAgents = activeAgents;
  }

  bool get isHealthy => health.check().healthy && _status == RuntimeStatus.running;
}
