import 'package:flutter/material.dart';

import '../../application/events/event_bus.dart';
import '../../application/events/event_publisher.dart';
import '../../application/events/event_store.dart';
import '../../application/events/in_memory_event_bus.dart';
import '../../application/events/in_memory_event_store.dart';
import '../../domain/events/event_envelope.dart';
import '../../domain/events/event_priority.dart';
import '../../domain/events/event_type.dart';

class EventBusScreen extends StatefulWidget {
  const EventBusScreen({super.key});

  @override
  State<EventBusScreen> createState() => _EventBusScreenState();
}

class _EventBusScreenState extends State<EventBusScreen> {
  final EventBus _bus = InMemoryEventBus();
  final EventStore _store = InMemoryEventStore();
  late final EventPublisher _publisher = EventPublisher(
    bus: _bus,
    store: _store,
  );

  int _received = 0;
  String _message = 'Event Bus hazır.';

  @override
  void initState() {
    super.initState();
    _bus.subscribe(_onEvent);
  }

  Future<void> _onEvent(EventEnvelope event) async {
    if (!mounted) return;

    setState(() {
      _received++;
      _message =
          '${event.type.value} • ${event.source} • ${event.priority.value}';
    });
  }

  Future<void> _send() async {
    await _publisher.publish(
      EventEnvelope(
        id: 'event-${DateTime.now().microsecondsSinceEpoch}',
        type: EventType.taskCreated,
        createdAt: DateTime.now().toUtc(),
        source: 'V16_UI',
        priority: EventPriority.normal,
        payload: const <String, Object?>{
          'message': 'V16 Event Bus testi',
        },
      ),
    );
  }

  @override
  void dispose() {
    _bus.unsubscribe(_onEvent);
    _bus.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARES • Event Bus'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Mesajlaşma merkezi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Modüller doğrudan birbirine bağlanmak yerine olaylar üzerinden haberleşir.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _send,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Test olayı gönder'),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: Text(_message),
              subtitle: Text('Alınan olay: $_received'),
            ),
          ),
        ],
      ),
    );
  }
}
