import '../../domain/runtime/runtime_result.dart';

abstract interface class RuntimeResultPipeline {
  Future<RuntimeResult> normalize(RuntimeResult result);
}

class DefaultRuntimeResultPipeline implements RuntimeResultPipeline {
  @override
  Future<RuntimeResult> normalize(RuntimeResult result) async => result;
}
