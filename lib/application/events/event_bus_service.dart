import '../../domain/events/event_envelope.dart';
import 'event_publisher.dart';

class EventBusService {
  EventBusService(this._publisher);

  final EventPublisher _publisher;

  Future<void> emit(EventEnvelope event) {
    return _publisher.publish(event);
  }
}
