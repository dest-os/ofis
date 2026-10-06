import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/events/event_publisher.dart';
import 'package:dest_os_ares/application/events/in_memory_event_bus.dart';
import 'package:dest_os_ares/application/events/in_memory_event_store.dart';
import 'package:dest_os_ares/domain/events/event_envelope.dart';
import 'package:dest_os_ares/domain/events/event_type.dart';

void main() {
  test('Publisher önce event store sonra Event Bus kullanır', () async {
    final bus = InMemoryEventBus();
    final store = InMemoryEventStore();

    EventEnvelope? received;
    bus.subscribe((event) async {
      received = event;
    });

    final publisher = EventPublisher(
      bus: bus,
      store: store,
    );

    final event = EventEnvelope(
      id: 'event-2',
      type: EventType.memoryWritten,
      createdAt: DateTime.utc(2026, 1, 1),
      source: 'test',
      payload: const <String, Object?>{},
    );

    await publisher.publish(event);

    final stored = await store.getAll();

    expect(stored, hasLength(1));
    expect(received?.type, EventType.memoryWritten);

    await bus.close();
  });
}
