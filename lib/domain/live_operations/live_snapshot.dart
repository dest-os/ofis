import 'live_operation.dart';

class LiveSnapshot {
  const LiveSnapshot({
    required this.operations,
    required this.generatedAt,
  });

  final List<LiveOperation> operations;
  final DateTime generatedAt;

  int get activeCount => operations.where((item) => item.status.isActive).length;

  int get runningCount =>
      operations.where((item) => item.status.name == 'running').length;

  int get waitingApprovalCount =>
      operations.where((item) => item.status.name == 'waitingApproval').length;
}
