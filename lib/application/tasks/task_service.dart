import '../../core/ids/ares_id.dart';
import '../../domain/events/task_created_event.dart';
import '../../domain/tasks/task.dart';

class TaskService {
  TaskCreatedEvent createTask({
    required String title,
    required String description,
  }) {
    final task = AresTask(
      id: AresId(_newId()),
      title: title,
      description: description,
    );

    return TaskCreatedEvent(
      eventId: AresId(_newId()),
      occurredAt: DateTime.now(),
      task: task,
    );
  }

  String _newId() {
    return '${DateTime.now().microsecondsSinceEpoch}';
  }
}
