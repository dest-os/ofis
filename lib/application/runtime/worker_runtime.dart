import '../../domain/runtime/execution_context.dart';
import '../../domain/runtime/runtime_result.dart';

abstract interface class WorkerRuntime {
  Future<RuntimeResult> execute(ExecutionContext context);
  Future<void> pause(String runId);
  Future<void> cancel(String runId);
}

class NoOpWorkerRuntime implements WorkerRuntime {
  @override
  Future<RuntimeResult> execute(ExecutionContext context) async {
    return const RuntimeResult(status: RuntimeResultStatus.success);
  }

  @override
  Future<void> pause(String runId) async {}

  @override
  Future<void> cancel(String runId) async {}
}
