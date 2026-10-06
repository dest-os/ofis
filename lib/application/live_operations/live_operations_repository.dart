import '../../domain/live_operations/live_operation.dart';

abstract interface class LiveOperationsRepository {
  Future<void> upsert(LiveOperation operation);

  Future<void> remove(String operationId);

  Future<LiveOperation?> getById(String operationId);

  Future<List<LiveOperation>> getAll();
}
