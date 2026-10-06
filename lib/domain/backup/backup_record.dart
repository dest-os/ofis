import 'backup_status.dart';
class BackupRecord {
  final String id; final BackupStatus status; final DateTime startedAt; final DateTime? completedAt; final String? error;
  const BackupRecord({required this.id, required this.status, required this.startedAt, this.completedAt, this.error});
}
