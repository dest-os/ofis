import '../../domain/audit/audit_event.dart';

abstract interface class AuditRepository {
  Future<void> add(AuditEvent event);
  Future<List<AuditEvent>> getAll();
}
