import '../../domain/database/entity_record.dart';
import '../database/database_manager.dart';

class PersistentRepository {
  PersistentRepository(this._database);

  final DatabaseManager _database;

  Future<void> save(EntityRecord record) async {
    final transaction = await _database.database.beginTransaction();

    try {
      final existing = await transaction.find(
        record.entityType,
        record.id,
      );

      if (existing == null) {
        await transaction.insert(record);
      } else {
        await transaction.update(record);
      }

      await transaction.commit();
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }

  Future<EntityRecord?> getById(
    String entityType,
    String id,
  ) {
    return _database.database.find(entityType, id);
  }

  Future<List<EntityRecord>> getAll(String entityType) {
    return _database.database.findAll(entityType);
  }

  Future<void> delete(String entityType, String id) async {
    final transaction = await _database.database.beginTransaction();

    try {
      await transaction.delete(entityType, id);
      await transaction.commit();
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }
}
