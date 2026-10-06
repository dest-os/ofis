import '../../domain/database/entity_record.dart';

abstract interface class DatabaseTransaction {
  Future<void> insert(EntityRecord record);
  Future<void> update(EntityRecord record);
  Future<void> delete(String entityType, String id);
  Future<EntityRecord?> find(String entityType, String id);
  Future<List<EntityRecord>> findAll(String entityType);
  Future<void> commit();
  Future<void> rollback();
}

class MemoryDatabaseTransaction implements DatabaseTransaction {
  MemoryDatabaseTransaction(this._store);

  final Map<String, Map<String, EntityRecord>> _store;
  final List<void Function()> _rollbackActions = <void Function()>[];

  @override
  Future<void> insert(EntityRecord record) async {
    final bucket = _store.putIfAbsent(
      record.entityType,
      () => <String, EntityRecord>{},
    );

    if (bucket.containsKey(record.id)) {
      throw StateError('Kayıt zaten mevcut: ${record.id}');
    }

    bucket[record.id] = record;
    _rollbackActions.add(() => bucket.remove(record.id));
  }

  @override
  Future<void> update(EntityRecord record) async {
    final bucket = _store.putIfAbsent(
      record.entityType,
      () => <String, EntityRecord>{},
    );
    final previous = bucket[record.id];

    if (previous == null) {
      throw StateError('Güncellenecek kayıt bulunamadı: ${record.id}');
    }

    bucket[record.id] = record;
    _rollbackActions.add(() => bucket[record.id] = previous);
  }

  @override
  Future<void> delete(String entityType, String id) async {
    final bucket = _store[entityType];
    final previous = bucket?[id];

    if (previous == null) {
      return;
    }

    bucket!.remove(id);
    _rollbackActions.add(() => bucket[id] = previous);
  }

  @override
  Future<EntityRecord?> find(String entityType, String id) async {
    return _store[entityType]?[id];
  }

  @override
  Future<List<EntityRecord>> findAll(String entityType) async {
    return List<EntityRecord>.unmodifiable(
      _store[entityType]?.values ?? const <EntityRecord>[],
    );
  }

  @override
  Future<void> commit() async {
    _rollbackActions.clear();
  }

  @override
  Future<void> rollback() async {
    for (final action in _rollbackActions.reversed) {
      action();
    }
    _rollbackActions.clear();
  }
}
