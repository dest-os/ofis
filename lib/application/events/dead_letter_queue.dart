import '../../domain/events/event_envelope.dart';

class DeadLetterQueue {
  final List<EventEnvelope> _events = <EventEnvelope>[];

  Future<void> add(EventEnvelope event) async {
    _events.add(event);
  }

  Future<List<EventEnvelope>> getAll() async {
    return List<EventEnvelope>.unmodifiable(_events);
  }
}
