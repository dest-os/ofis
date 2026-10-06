import '../../domain/runtime/runtime_health.dart';

class RuntimeHealthService {
  RuntimeHealth check() {
    return RuntimeHealth(
      healthy: true,
      message: 'Üretim çalışma çekirdeği hazır.',
      checkedAt: DateTime.now(),
    );
  }
}
