/// Represents one local/remote dependency health state.
class DependencyHealth {
  /// Creates a dependency health state.
  const DependencyHealth({required this.name, required this.ready, required this.message});

  /// Dependency name.
  final String name;
  /// Whether the dependency is usable.
  final bool ready;
  /// Human-readable status or setup guidance.
  final String message;
}

/// Aggregates AI and ffmpeg readiness for the tablet production center.
class EnvironmentHealth {
  /// Creates an immutable environment health snapshot.
  const EnvironmentHealth({required this.localAi, required this.freeAi, required this.ffmpeg});

  /// Local AI state.
  final DependencyHealth localAi;
  /// Free remote AI state.
  final DependencyHealth freeAi;
  /// ffmpeg state.
  final DependencyHealth ffmpeg;
}

/// Application facade for startup dependency health checks.
abstract interface class EnvironmentHealthService {
  /// Checks configured dependencies.
  Future<EnvironmentHealth> check();
}
