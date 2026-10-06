import '../../core/ids/ares_id.dart';
import '../../core/time/ares_clock.dart';
import '../../domain/notifications/notification.dart';
import 'notification_repository.dart';

class NotificationService {
  const NotificationService(this._repository, this._clock);

  final NotificationRepository _repository;
  final AresClock _clock;

  Future<AresNotification> notify({
    required NotificationLevel level,
    required String title,
    required String message,
    String? taskId,
    bool requiresAction = false,
  }) async {
    final notification = AresNotification(
      id: AresId.generate(),
      level: level,
      title: title,
      message: message,
      createdAt: _clock.now(),
      taskId: taskId,
      requiresAction: requiresAction || level == NotificationLevel.actionRequired || level == NotificationLevel.critical,
    );
    await _repository.add(notification);
    return notification;
  }
}
