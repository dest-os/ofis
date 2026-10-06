import '../../core/ids/ares_id.dart';

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.actor,
    required this.action,
    required this.target,
    required this.timestamp,
    this.taskId,
    this.approvalId,
    this.riskLevel = 'NORMAL',
    this.costAmount = 0,
    this.result = 'RECORDED',
    this.details = const <String, String>{},
  });

  final AresId id;
  final String actor;
  final String action;
  final String target;
  final DateTime timestamp;
  final String? taskId;
  final String? approvalId;
  final String riskLevel;
  final double costAmount;
  final String result;
  final Map<String, String> details;
}
