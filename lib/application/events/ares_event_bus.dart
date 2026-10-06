import '../../domain/events/ares_event.dart';

abstract interface class AresEventBus {
  Future<void> publish(AresEvent event);

  Stream<AresEvent> get events;
}

class InMemoryAresEventBus implements AresEventBus {
  InMemoryAresEventBus();

  final Stream<AresEvent> _events = const Stream.empty();

  @override
  Stream<AresEvent> get events => _events;

  @override
  Future<void> publish(AresEvent event) async {
    // V2 temel sözleşmesidir.
    // Kalıcı Event Bus sonraki altyapı aşamasında bağlanacaktır.
  }
}
