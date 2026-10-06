import '../../domain/events/event_envelope.dart';

typedef EventHandler = Future<void> Function(EventEnvelope event);

abstract interface class EventBus {
  Future<void> publish(EventEnvelope event);
  void subscribe(EventHandler handler);
  void unsubscribe(EventHandler handler);
  Future<void> close();
}
