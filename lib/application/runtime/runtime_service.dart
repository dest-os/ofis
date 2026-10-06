import '../../domain/runtime/runtime_task.dart';
import 'runtime_kernel.dart';

class RuntimeService {
  RuntimeService({required RuntimeKernel kernel}) : _kernel = kernel;

  final RuntimeKernel _kernel;

  Future<void> submit(RuntimeTask task) => _kernel.submit(task);
  Future<RuntimeTask?> tick() => _kernel.runNext();
  Future<void> pause(RuntimeTask task) => _kernel.pause(task);
  Future<void> cancel(RuntimeTask task) => _kernel.cancel(task);
}
