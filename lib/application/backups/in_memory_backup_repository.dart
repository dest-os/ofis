import '../../domain/backups/backup_record.dart';
import 'backup_repository.dart';

class InMemoryBackupRepository implements BackupRepository {
  final List<BackupRecord> _items = <BackupRecord>[];

  @override
  Future<void> add(BackupRecord record) async => _items.add(record);

  @override
  Future<List<BackupRecord>> getAll() async => List.unmodifiable(_items);
}
