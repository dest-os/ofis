import 'event_priority.dart';
import 'event_type.dart';

class EventEnvelope {
  const EventEnvelope({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.source,
    required this.payload,
    this.priority = EventPriority.normal,
    this.correlationId,
    this.causationId,
    this.taskId,
    this.projectId,
    this.agentId,
    this.retryCount = 0,
  });

  final String id;
  final EventType type;
  final DateTime createdAt;
  final String source;
  final Map<String, Object?> payload;
  final EventPriority priority;
  final String? correlationId;
  final String? causationId;
  final String? taskId;
  final String? projectId;
  final String? agentId;
  final int retryCount;

  EventEnvelope copyWith({
    String? id,
    EventType? type,
    DateTime? createdAt,
    String? source,
    Map<String, Object?>? payload,
    EventPriority? priority,
    String? correlationId,
    String? causationId,
    String? taskId,
    String? projectId,
    String? agentId,
    int? retryCount,
  }) {
    return EventEnvelope(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      correlationId: correlationId ?? this.correlationId,
      causationId: causationId ?? this.causationId,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      agentId: agentId ?? this.agentId,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
