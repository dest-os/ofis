import '../../domain/archive/work_archive_entry.dart';

abstract interface class WorkArchiveRepository {
  Future<void> save(WorkArchiveEntry entry);

  Future<List<WorkArchiveEntry>> search(String query);

  Future<void> delete(String id);
}
