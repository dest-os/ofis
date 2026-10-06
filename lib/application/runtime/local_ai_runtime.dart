import '../../domain/runtime/ai_runtime_request.dart';
import '../../domain/runtime/runtime_result.dart';

abstract interface class LocalAiRuntime {
  Future<RuntimeResult> run(AiRuntimeRequest request);
  Future<bool> isAvailable();
}

class UnconfiguredLocalAiRuntime implements LocalAiRuntime {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<RuntimeResult> run(AiRuntimeRequest request) async {
    return const RuntimeResult(
      status: RuntimeResultStatus.failed,
      error: 'Yerel AI runtime henüz yapılandırılmadı.',
    );
  }
}
