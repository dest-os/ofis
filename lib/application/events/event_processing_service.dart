import '../../domain/events/event_envelope.dart';
import 'dead_letter_queue.dart';
import 'event_bus.dart';
import 'event_store.dart';
import 'retry_policy.dart';

class EventProcessingService {
  EventProcessingService({
    required EventBus bus,
    required EventStore store,
    RetryPolicy? retryPolicy,
    DeadLetterQueue? deadLetterQueue,
  })  : _bus = bus,
        _store = store,
        _retryPolicy = retryPolicy ?? const RetryPolicy(),
        _deadLetterQueue = deadLetterQueue ?? DeadLetterQueue();

  final EventBus _bus;
  final EventStore _store;
  final RetryPolicy _retryPolicy;
  final DeadLetterQueue _deadLetterQueue;

  Future<void> process(EventEnvelope event) async {
    try {
      await _bus.publish(event);
    } catch (_) {
      if (_retryPolicy.canRetry(event.retryCount)) {
        final retry = event.copyWith(
          retryCount: event.retryCount + 1,
        );
        await _store.append(retry);
        await process(retry);
      } else {
        await _deadLetterQueue.add(event);
      }
    }
  }

  DeadLetterQueue get deadLetterQueue => _deadLetterQueue;
}
