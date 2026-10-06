import '../../domain/costs/cost_record.dart';
import 'cost_repository.dart';

class InMemoryCostRepository implements CostRepository {
  final Map<String, CostRecord> _records = {};

  @override
  Future<void> save(CostRecord record) async {
    _records[record.id.value] = record;
  }

  @override
  Future<CostRecord?> getById(String id) async => _records[id];

  @override
  Future<List<CostRecord>> getAll() async => _records.values.toList(growable: false);

  @override
  Future<List<CostRecord>> getByProject(String projectId) async =>
      _records.values.where((record) => record.projectId == projectId).toList(growable: false);
}
