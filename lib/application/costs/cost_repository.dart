import '../../domain/costs/cost_record.dart';

abstract interface class CostRepository {
  Future<void> save(CostRecord record);
  Future<CostRecord?> getById(String id);
  Future<List<CostRecord>> getAll();
  Future<List<CostRecord>> getByProject(String projectId);
}
