import '../../domain/memory/memory_record.dart';
import 'memory_repository.dart';

class InMemoryMemoryRepository implements MemoryRepository {
  final Map<String, MemoryRecord> _items = <String, MemoryRecord>{};

  @override
  Future<void> save(MemoryRecord memory) async {
    final safeConfidence = memory.confidence.clamp(0.0, 1.0);
    _items[memory.id] = memory.copyWith(confidence: safeConfidence);
  }

  @override
  Future<MemoryRecord?> getById(String id) async => _items[id];

  @override
  Future<List<MemoryRecord>> getAll() async {
    return List<MemoryRecord>.unmodifiable(
      _items.values.where((item) => !item.archived),
    );
  }

  @override
  Future<List<MemoryRecord>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();

    final results = (await getAll()).where(
      (item) =>
          item.content.toLowerCase().contains(normalized) ||
          item.tags.any((tag) => tag.toLowerCase().contains(normalized)),
    );

    return List<MemoryRecord>.unmodifiable(results);
  }

  @override
  Future<void> archive(String id) async {
    final current = _items[id];
    if (current == null) return;
    _items[id] = current.copyWith(archived: true);
  }

  @override
  Future<void> remove(String id) async {
    _items.remove(id);
  }
}
