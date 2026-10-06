import '../../domain/events/event_envelope.dart';
import 'event_bus.dart';

class EventRouter {
  EventRouter(this._bus);

  final EventBus _bus;
  final Map<String, List<EventHandler>> _routes =
      <String, List<EventHandler>>{};

  void register(EventTypeKey key, EventHandler handler) {
    _routes.putIfAbsent(key.value, () => <EventHandler>[]).add(handler);
    _bus.subscribe(_dispatch);
  }

  Future<void> _dispatch(EventEnvelope event) async {
    final handlers = _routes[event.type.name] ?? const <EventHandler>[];

    for (final handler in List<EventHandler>.from(handlers)) {
      await handler(event);
    }
  }
}

class EventTypeKey {
  const EventTypeKey(this.value);

  final String value;
}
