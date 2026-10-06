import '../../domain/database/entity_record.dart';
import '../../domain/memory/memory_record.dart';
import '../../domain/memory/memory_scope.dart';
import '../../domain/memory/memory_type.dart';
import '../database/database_manager.dart';
import '../persistence/persistent_repository.dart';
import 'memory_repository.dart';

class PersistentMemoryRepository implements MemoryRepository {
  PersistentMemoryRepository(DatabaseManager database)
      : _repository = PersistentRepository(database);

  final PersistentRepository _repository;

  static const String entityType = 'memory';

  @override
  Future<void> save(MemoryRecord memory) async {
    await _repository.save(EntityRecordAdapter.toEntity(memory));
  }

  @override
  Future<MemoryRecord?> getById(String id) async {
    final record = await _repository.getById(entityType, id);
    return record == null ? null : EntityRecordAdapter.fromEntity(record);
  }

  @override
  Future<List<MemoryRecord>> getAll() async {
    final records = await _repository.getAll(entityType);
    return <MemoryRecord>[
      for (final record in records) EntityRecordAdapter.fromEntity(record),
    ];
  }

  @override
  Future<List<MemoryRecord>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final all = await getAll();
    if (normalized.isEmpty) return all;
    return all
        .where(
          (memory) =>
              memory.content.toLowerCase().contains(normalized) ||
              memory.tags.any((tag) => tag.toLowerCase().contains(normalized)),
        )
        .toList(growable: false);
  }

  @override
  Future<void> archive(String id) async {
    final current = await getById(id);
    if (current == null) return;
    await save(current.copyWith(archived: true));
  }

  @override
  Future<void> remove(String id) {
    return _repository.delete(entityType, id);
  }
}

class EntityRecordAdapter {
  const EntityRecordAdapter._();

  static EntityRecord toEntity(MemoryRecord memory) {
    final now = DateTime.now().toUtc();
    return EntityRecord(
      id: memory.id,
      entityType: PersistentMemoryRepository.entityType,
      createdAt: memory.createdAt,
      updatedAt: now,
      data: <String, Object?>{
        'content': memory.content,
        'type': memory.type.name,
        'scope': memory.scope.name,
        'tags': memory.tags,
        'archived': memory.archived,
        'projectId': memory.projectId,
        'taskId': memory.taskId,
        'confidence': memory.confidence,
        'source': memory.source,
      },
    );
  }

  static MemoryRecord fromEntity(EntityRecord record) {
    final data = record.data;
    final tagsRaw = data['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    return MemoryRecord(
      id: record.id,
      content: '${data['content'] ?? ''}',
      type: MemoryType.values.firstWhere(
        (item) => item.name == data['type'],
        orElse: () => MemoryType.values.first,
      ),
      scope: MemoryScope.values.firstWhere(
        (item) => item.name == data['scope'],
        orElse: () => MemoryScope.values.first,
      ),
      createdAt: record.createdAt,
      projectId: data['projectId']?.toString(),
      taskId: data['taskId']?.toString(),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
      source: data['source']?.toString(),
      tags: tags,
      archived: data['archived'] == true,
    );
  }
}
