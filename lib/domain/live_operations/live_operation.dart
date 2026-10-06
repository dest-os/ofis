import 'live_operation_status.dart';

class LiveOperation {
  const LiveOperation({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    required this.updatedAt,
    this.taskId,
    this.projectId,
    this.agentId,
    this.currentStep,
    this.message,
    this.priority = 0,
  });

  final String id;
  final String title;
  final LiveOperationStatus status;
  final double progress;
  final DateTime updatedAt;
  final String? taskId;
  final String? projectId;
  final String? agentId;
  final String? currentStep;
  final String? message;
  final int priority;

  LiveOperation copyWith({
    String? id,
    String? title,
    LiveOperationStatus? status,
    double? progress,
    DateTime? updatedAt,
    String? taskId,
    String? projectId,
    String? agentId,
    String? currentStep,
    String? message,
    int? priority,
  }) {
    return LiveOperation(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      updatedAt: updatedAt ?? this.updatedAt,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      agentId: agentId ?? this.agentId,
      currentStep: currentStep ?? this.currentStep,
      message: message ?? this.message,
      priority: priority ?? this.priority,
    );
  }
}
