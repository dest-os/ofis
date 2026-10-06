import '../../application/archive/work_archive_repository.dart';
import '../../core/ids/ares_id.dart';
import '../../domain/archive/work_archive_entry.dart';
import '../storage/json_file_store.dart';

/// Çalışma arşivini diskte kalıcı tutar. Silinen kayıt gerçekten dosyadan kaldırılır.
class FileWorkArchiveRepository implements WorkArchiveRepository {
  FileWorkArchiveRepository(this._store);

  static const String _fileName = 'work_archive';

  final JsonFileStore _store;
  Map<String, WorkArchiveEntry>? _cache;
  Future<void> _writeQueue = Future<void>.value();

  Future<Map<String, WorkArchiveEntry>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final loaded = <String, WorkArchiveEntry>{};
    final raw = await _store.read(_fileName);
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        try {
          final entry = _fromJson(Map<String, dynamic>.from(item));
          loaded[entry.id.value] = entry;
        } catch (_) {
          // Bozuk tek kayıt diğerlerini etkilemesin.
        }
      }
    }
    _cache = loaded;
    return loaded;
  }

  Future<void> _persist(Map<String, WorkArchiveEntry> entries) {
    final snapshot = entries.values.map(_toJson).toList(growable: false);
    _writeQueue = _writeQueue.catchError((Object _) {}).then((_) => _store.write(_fileName, snapshot));
    return _writeQueue;
  }

  @override
  Future<void> save(WorkArchiveEntry entry) async {
    final entries = await _load();
    entries[entry.id.value] = entry;
    await _persist(entries);
  }

  @override
  Future<List<WorkArchiveEntry>> search(String query) async {
    final entries = await _load();
    final normalized = query.trim().toLowerCase();
    final result = entries.values.where((entry) {
      if (entry.isDeleted) return false;
      if (normalized.isEmpty) return true;
      return entry.title.toLowerCase().contains(normalized) ||
          entry.summary.toLowerCase().contains(normalized) ||
          entry.tags.any((tag) => tag.toLowerCase().contains(normalized));
    }).toList();
    result.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List<WorkArchiveEntry>.unmodifiable(result);
  }

  @override
  Future<void> delete(String id) async {
    final entries = await _load();
    if (entries.remove(id) == null) return;
    await _persist(entries);
  }

  Map<String, Object?> _toJson(WorkArchiveEntry entry) => <String, Object?>{
        'id': entry.id.value,
        'title': entry.title,
        'summary': entry.summary,
        'completedAt': entry.completedAt.toIso8601String(),
        'taskId': entry.taskId,
        'projectId': entry.projectId,
        'memoryNamespace': entry.memoryNamespace,
        'tags': entry.tags,
        'reusable': entry.reusable,
      };

  WorkArchiveEntry _fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    return WorkArchiveEntry(
      id: AresId(json['id'] as String),
      title: json['title'] as String,
      summary: json['summary'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      taskId: json['taskId'] as String?,
      projectId: json['projectId'] as String?,
      memoryNamespace: json['memoryNamespace'] as String?,
      tags: tags is List ? tags.whereType<String>().toList(growable: false) : const <String>[],
      reusable: json['reusable'] is bool ? json['reusable'] as bool : true,
    );
  }
}
