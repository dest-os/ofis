import '../../domain/events/event_envelope.dart';
import 'event_store.dart';

class InMemoryEventStore implements EventStore {
  final List<EventEnvelope> _events = <EventEnvelope>[];

  @override
  Future<void> append(EventEnvelope event) async {
    _events.add(event);
  }

  @override
  Future<List<EventEnvelope>> getAll() async {
    return List<EventEnvelope>.unmodifiable(_events);
  }

  @override
  Future<List<EventEnvelope>> getByCorrelationId(
    String correlationId,
  ) async {
    return List<EventEnvelope>.unmodifiable(
      _events.where((event) => event.correlationId == correlationId),
    );
  }
}
