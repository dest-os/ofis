import '../../core/ids/ares_id.dart';
import '../tasks/task.dart';
import 'ares_event.dart';

class TaskCreatedEvent extends AresEvent {
  const TaskCreatedEvent({
    required super.eventId,
    required super.occurredAt,
    required this.task,
  });

  final AresTask task;
}
