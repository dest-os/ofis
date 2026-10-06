import '../../domain/archive/work_archive_entry.dart';
import 'work_archive_repository.dart';

class WorkArchiveService {
  final WorkArchiveRepository repository;

  WorkArchiveService(this.repository);

  Future<void> archive(WorkArchiveEntry entry) async {
    if (entry.title.trim().isEmpty) {
      throw ArgumentError('Arşiv başlığı boş olamaz.');
    }
    if (entry.summary.trim().isEmpty) {
      throw ArgumentError('Arşiv özeti boş olamaz.');
    }
    if (entry.isDeleted) {
      throw ArgumentError('Silinmiş kayıt arşive tekrar yazılamaz.');
    }
    await repository.save(entry);
  }

  Future<List<WorkArchiveEntry>> findReusable(String query) async {
    final entries = await repository.search(query);
    return entries.where((entry) => entry.reusable && !entry.isDeleted).toList(growable: false);
  }

  Future<void> softDelete(String id) => repository.delete(id);
}
