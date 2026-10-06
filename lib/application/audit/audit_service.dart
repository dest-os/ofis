import '../../core/ids/ares_id.dart';
import '../../core/time/ares_clock.dart';
import '../../domain/audit/audit_event.dart';
import 'audit_repository.dart';

class AuditService {
  const AuditService(this._repository, this._clock);

  final AuditRepository _repository;
  final AresClock _clock;

  Future<AuditEvent> record({
    required String actor,
    required String action,
    required String target,
    String? taskId,
    String? approvalId,
    String riskLevel = 'NORMAL',
    double costAmount = 0,
    String result = 'RECORDED',
    Map<String, String> details = const <String, String>{},
  }) async {
    final event = AuditEvent(
      id: AresId.generate(),
      actor: actor,
      action: action,
      target: target,
      timestamp: _clock.now(),
      taskId: taskId,
      approvalId: approvalId,
      riskLevel: riskLevel,
      costAmount: costAmount,
      result: result,
      details: Map.unmodifiable(details),
    );
    await _repository.add(event);
    return event;
  }
}
