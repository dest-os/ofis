import '../../domain/live_operations/live_operation.dart';
import '../../domain/live_operations/live_operation_status.dart';
import '../../domain/live_operations/live_snapshot.dart';
import 'live_operations_repository.dart';

class LiveOperationsService {
  LiveOperationsService(this._repository);

  final LiveOperationsRepository _repository;

  Future<void> publish(LiveOperation operation) {
    final safeProgress = operation.progress.clamp(0.0, 1.0);
    return _repository.upsert(
      operation.copyWith(progress: safeProgress),
    );
  }

  Future<void> updateProgress({
    required String operationId,
    required double progress,
    LiveOperationStatus? status,
    String? currentStep,
    String? message,
  }) async {
    final current = await _repository.getById(operationId);
    if (current == null) {
      throw StateError('Canlı operasyon bulunamadı: $operationId');
    }

    await publish(
      current.copyWith(
        progress: progress,
        status: status,
        currentStep: currentStep,
        message: message,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<LiveSnapshot> snapshot() async {
    final items = await _repository.getAll();
    items.sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      if (priority != 0) return priority;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return LiveSnapshot(
      operations: List.unmodifiable(items),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> remove(String operationId) {
    return _repository.remove(operationId);
  }
}
