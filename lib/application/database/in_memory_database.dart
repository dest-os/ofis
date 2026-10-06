import '../../domain/database/entity_record.dart';
import 'database_transaction.dart';

class InMemoryDatabase {
  final Map<String, Map<String, EntityRecord>> _store =
      <String, Map<String, EntityRecord>>{};

  Future<DatabaseTransaction> beginTransaction() async {
    return MemoryDatabaseTransaction(_store);
  }

  Future<EntityRecord?> find(String entityType, String id) async {
    return _store[entityType]?[id];
  }

  Future<List<EntityRecord>> findAll(String entityType) async {
    return List<EntityRecord>.unmodifiable(
      _store[entityType]?.values ?? const <EntityRecord>[],
    );
  }
}
