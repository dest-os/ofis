import '../../core/ids/ares_id.dart';
import 'cost_status.dart';

class CostRecord {
  const CostRecord({
    required this.id,
    required this.status,
    required this.resourceType,
    required this.provider,
    required this.model,
    required this.currency,
    required this.estimatedAmount,
    required this.actualAmount,
    required this.createdAt,
    this.taskId,
    this.projectId,
    this.approvalId,
  });

  final AresId id;
  final CostStatus status;
  final String resourceType;
  final String provider;
  final String model;
  final String currency;
  final double estimatedAmount;
  final double actualAmount;
  final DateTime createdAt;
  final String? taskId;
  final String? projectId;
  final String? approvalId;

  bool get hasActualCost => actualAmount > 0;
  bool get requiresApproval => status == CostStatus.pendingApproval;
}
