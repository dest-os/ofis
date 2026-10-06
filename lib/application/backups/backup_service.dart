import '../../core/ids/ares_id.dart';
import '../../core/time/ares_clock.dart';
import '../../domain/backups/backup_record.dart';
import 'backup_repository.dart';

class BackupService {
  const BackupService(this._repository, this._clock);

  final BackupRepository _repository;
  final AresClock _clock;

  Future<BackupRecord> createBackup({
    required String version,
    required int itemCount,
    required String integrityHash,
    String location = 'LOCAL',
  }) async {
    final record = BackupRecord(
      id: AresId.generate(),
      createdAt: _clock.now(),
      version: version,
      status: BackupStatus.created,
      itemCount: itemCount,
      integrityHash: integrityHash,
      location: location,
      encrypted: true,
    );
    await _repository.add(record);
    return record;
  }

  Future<BackupRecord> verify(BackupRecord record) async {
    if (record.integrityHash.isEmpty) {
      throw ArgumentError('Yedek bütünlük değeri boş olamaz.');
    }
    final verified = BackupRecord(
      id: record.id,
      createdAt: record.createdAt,
      version: record.version,
      status: BackupStatus.verified,
      itemCount: record.itemCount,
      integrityHash: record.integrityHash,
      location: record.location,
      encrypted: record.encrypted,
    );
    await _repository.add(verified);
    return verified;
  }
}
