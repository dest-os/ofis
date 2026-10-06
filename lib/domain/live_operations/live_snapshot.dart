import 'live_operation.dart';
import 'live_operation_status.dart';

class LiveSnapshot {
  const LiveSnapshot({
    required this.operations,
    required this.generatedAt,
  });

  final List<LiveOperation> operations;
  final DateTime generatedAt;

  int get activeCount =>
      operations.where((item) => item.status.isActive).length;

  int get runningCount =>
      operations.where((item) => item.status == LiveOperationStatus.running).length;

  int get waitingApprovalCount => operations
      .where((item) => item.status == LiveOperationStatus.waitingApproval)
      .length;
}
