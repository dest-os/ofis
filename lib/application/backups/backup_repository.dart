import '../../domain/backups/backup_record.dart';

abstract interface class BackupRepository {
  Future<void> add(BackupRecord record);
  Future<List<BackupRecord>> getAll();
}
