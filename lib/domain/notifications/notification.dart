import '../../core/ids/ares_id.dart';

class AresNotification {
  const AresNotification({
    required this.id,
    required this.level,
    required this.title,
    required this.message,
    required this.createdAt,
    this.taskId,
    this.requiresAction = false,
    this.read = false,
  });

  final AresId id;
  final NotificationLevel level;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? taskId;
  final bool requiresAction;
  final bool read;
}

enum NotificationLevel {
  info,
  notice,
  important,
  actionRequired,
  critical,
}
