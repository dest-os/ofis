import '../../domain/audit/audit_event.dart';
import 'audit_repository.dart';

class InMemoryAuditRepository implements AuditRepository {
  final List<AuditEvent> _items = <AuditEvent>[];

  @override
  Future<void> add(AuditEvent event) async => _items.add(event);

  @override
  Future<List<AuditEvent>> getAll() async => List.unmodifiable(_items);
}
