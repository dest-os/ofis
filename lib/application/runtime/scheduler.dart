import '../../domain/runtime/runtime_task.dart';

abstract interface class RuntimeScheduler {
  Future<void> schedule(RuntimeTask task);
  Future<RuntimeTask?> next();
  Future<void> cancel(String taskId);
  Future<List<RuntimeTask>> pending();
}

class InMemoryRuntimeScheduler implements RuntimeScheduler {
  final List<RuntimeTask> _queue = <RuntimeTask>[];

  @override
  Future<void> schedule(RuntimeTask task) async {
    if (_queue.any((item) => item.task.id.value == task.task.id.value)) return;
    _queue.add(task);
  }

  @override
  Future<RuntimeTask?> next() async {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  @override
  Future<void> cancel(String taskId) async {
    _queue.removeWhere((item) => item.task.id.value == taskId);
  }

  @override
  Future<List<RuntimeTask>> pending() async => List.unmodifiable(_queue);
}
