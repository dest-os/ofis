import '../../domain/events/event_envelope.dart';
import 'event_bus.dart';
import 'event_store.dart';

class EventPublisher {
  EventPublisher({
    required EventBus bus,
    required EventStore store,
  })  : _bus = bus,
        _store = store;

  final EventBus _bus;
  final EventStore _store;

  Future<void> publish(EventEnvelope event) async {
    await _store.append(event);
    await _bus.publish(event);
  }
}
