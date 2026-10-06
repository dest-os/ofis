import '../../domain/events/event_envelope.dart';
import 'event_bus.dart';

class InMemoryEventBus implements EventBus {
  final List<EventHandler> _handlers = <EventHandler>[];
  bool _closed = false;

  @override
  Future<void> publish(EventEnvelope event) async {
    if (_closed) {
      throw StateError('Event Bus kapalı.');
    }

    final handlers = List<EventHandler>.from(_handlers);

    for (final handler in handlers) {
      await handler(event);
    }
  }

  @override
  void subscribe(EventHandler handler) {
    if (_closed) {
      throw StateError('Event Bus kapalı.');
    }

    if (!_handlers.contains(handler)) {
      _handlers.add(handler);
    }
  }

  @override
  void unsubscribe(EventHandler handler) {
    _handlers.remove(handler);
  }

  @override
  Future<void> close() async {
    _closed = true;
    _handlers.clear();
  }
}
