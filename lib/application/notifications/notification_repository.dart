import '../../domain/notifications/notification.dart';

abstract interface class NotificationRepository {
  Future<void> add(AresNotification notification);
  Future<List<AresNotification>> getAll();
}
