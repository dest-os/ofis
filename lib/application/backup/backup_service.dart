import '../../domain/backup/backup_manifest.dart';
import '../../domain/backup/backup_record.dart';
import '../../domain/backup/backup_status.dart';
class BackupService {
  BackupRecord createBackup({required BackupManifest manifest}) {
    if (!manifest.encrypted) return BackupRecord(id: manifest.id, status: BackupStatus.failed, startedAt: manifest.createdAt, completedAt: DateTime.now(), error: 'Üretim yedeği şifreli olmalıdır.');
    if (manifest.integrityHash.trim().isEmpty) return BackupRecord(id: manifest.id, status: BackupStatus.failed, startedAt: manifest.createdAt, completedAt: DateTime.now(), error: 'Yedek bütünlük doğrulaması eksik.');
    return BackupRecord(id: manifest.id, status: BackupStatus.completed, startedAt: manifest.createdAt, completedAt: DateTime.now());
  }
}
