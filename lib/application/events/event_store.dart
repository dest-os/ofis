import '../../domain/events/event_envelope.dart';

abstract interface class EventStore {
  Future<void> append(EventEnvelope event);
  Future<List<EventEnvelope>> getAll();
  Future<List<EventEnvelope>> getByCorrelationId(String correlationId);
}
