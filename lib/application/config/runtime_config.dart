import 'feature_flags.dart';

class RuntimeConfig {
  const RuntimeConfig({
    this.appName = 'DEST-OS ARES',
    this.version = 'V28',
    this.heartbeatInterval = const Duration(seconds: 10),
    this.startupTimeout = const Duration(seconds: 30),
    this.shutdownTimeout = const Duration(seconds: 15),
    this.maxRetryCount = 3,
    this.flags = const FeatureFlags(),
  });

  final String appName;
  final String version;
  final Duration heartbeatInterval;
  final Duration startupTimeout;
  final Duration shutdownTimeout;
  final int maxRetryCount;
  final FeatureFlags flags;
}
