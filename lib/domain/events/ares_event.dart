import '../../core/ids/ares_id.dart';

abstract class AresEvent {
  const AresEvent({
    required this.eventId,
    required this.occurredAt,
  });

  final AresId eventId;
  final DateTime occurredAt;
}
