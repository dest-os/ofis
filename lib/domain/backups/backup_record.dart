import '../../core/ids/ares_id.dart';

class BackupRecord {
  const BackupRecord({
    required this.id,
    required this.createdAt,
    required this.version,
    required this.status,
    required this.itemCount,
    required this.integrityHash,
    this.location = 'LOCAL',
    this.encrypted = true,
  });

  final AresId id;
  final DateTime createdAt;
  final String version;
  final BackupStatus status;
  final int itemCount;
  final String integrityHash;
  final String location;
  final bool encrypted;
}

enum BackupStatus { created, verified, failed, restored }
