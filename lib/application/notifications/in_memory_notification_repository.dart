import '../../domain/notifications/notification.dart';
import 'notification_repository.dart';

class InMemoryNotificationRepository implements NotificationRepository {
  final List<AresNotification> _items = <AresNotification>[];

  @override
  Future<void> add(AresNotification notification) async => _items.add(notification);

  @override
  Future<List<AresNotification>> getAll() async => List.unmodifiable(_items);
}
