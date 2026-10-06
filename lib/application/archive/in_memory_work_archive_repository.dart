import '../../domain/archive/work_archive_entry.dart';
import 'work_archive_repository.dart';

class InMemoryWorkArchiveRepository implements WorkArchiveRepository {
  final Map<String, WorkArchiveEntry> _entries = {};

  @override
  Future<void> save(WorkArchiveEntry entry) async {
    _entries[entry.id.value] = entry;
  }

  @override
  Future<List<WorkArchiveEntry>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    return _entries.values
        .where((entry) =>
            !entry.isDeleted &&
            (normalized.isEmpty ||
                entry.title.toLowerCase().contains(normalized) ||
                entry.summary.toLowerCase().contains(normalized) ||
                entry.tags.any((tag) => tag.toLowerCase().contains(normalized))))
        .toList(growable: false);
  }

  @override
  Future<void> delete(String id) async {
    final entry = _entries[id];
    if (entry == null) return;
    _entries[id] = entry.copyWith(
      isDeleted: true,
      reusable: false,
      deletedAt: DateTime.now(),
    );
  }
}
