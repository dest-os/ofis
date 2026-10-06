import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/events/in_memory_event_bus.dart';
import 'package:dest_os_ares/domain/events/event_envelope.dart';
import 'package:dest_os_ares/domain/events/event_priority.dart';
import 'package:dest_os_ares/domain/events/event_type.dart';

void main() {
  test('Event Bus olayı aboneye iletir', () async {
    final bus = InMemoryEventBus();
    EventEnvelope? received;

    bus.subscribe((event) async {
      received = event;
    });

    final event = EventEnvelope(
      id: 'event-1',
      type: EventType.taskCreated,
      createdAt: DateTime.utc(2026, 1, 1),
      source: 'test',
      priority: EventPriority.normal,
      payload: const <String, Object?>{'value': 'ARES'},
    );

    await bus.publish(event);

    expect(received?.id, 'event-1');
    await bus.close();
  });
}
