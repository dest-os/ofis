import 'runtime_module.dart';

/// Represents an explicitly registered production runtime boundary.
///
/// The module owns lifecycle state and provides a concrete runtime registration
/// point without pretending to execute work that belongs to its dedicated
/// subsystem.
class OperationalRuntimeModule implements RuntimeModule {
  /// Creates a runtime boundary with [name].
  OperationalRuntimeModule(this.name);

  @override
  final String name;

  bool _running = false;

  /// Whether this runtime boundary is active.
  bool get running => _running;

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}
