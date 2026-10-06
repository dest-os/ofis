import '../../domain/audit/audit_event.dart';

abstract class SecurityAuditService {
  Future<void> record(AuditEvent event);
}

class InMemorySecurityAuditService implements SecurityAuditService {
  final List<AuditEvent> events = [];

  @override
  Future<void> record(AuditEvent event) async => events.add(event);
}
