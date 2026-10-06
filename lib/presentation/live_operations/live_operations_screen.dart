import 'package:flutter/material.dart';

import '../../application/live_operations/live_operations_store.dart';
import '../../domain/live_operations/live_operation.dart';
import '../../domain/live_operations/live_operation_status.dart';

class LiveOperationsScreen extends StatelessWidget {
  const LiveOperationsScreen({super.key, required this.store});

  final LiveOperationsStore store;

  String _status(LiveOperationStatus value) {
    switch (value) {
      case LiveOperationStatus.queued:
        return 'Bekliyor';
      case LiveOperationStatus.running:
        return 'Çalışıyor';
      case LiveOperationStatus.completed:
        return 'Tamam';
      case LiveOperationStatus.failed:
        return 'Hata';
      case LiveOperationStatus.waitingApproval:
        return 'Onay bekliyor';
      case LiveOperationStatus.paused:
        return 'Bekliyor';
      case LiveOperationStatus.blocked:
        return 'Bekliyor';
      case LiveOperationStatus.cancelled:
        return 'İptal';
    }
  }

  Color _statusColor(BuildContext context, LiveOperationStatus value) {
    switch (value) {
      case LiveOperationStatus.running:
        return Colors.cyanAccent;
      case LiveOperationStatus.completed:
        return Colors.greenAccent;
      case LiveOperationStatus.failed:
        return Colors.redAccent;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canlı Operasyon')),
      body: StreamBuilder<void>(
        stream: store.changes,
        builder: (context, _) {
          final active = store.activeOperation;
          final operations = store.operations;
          final events = store.events;
          if (active == null && operations.isEmpty && events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Hazır. Şu anda çalışan bir üretim yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active != null) ...[
                _Section(
                  title: 'AKTİF GÖREV',
                  child: _OperationCard(
                    operation: active,
                    status: _status(active.status),
                    color: _statusColor(context, active.status),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (events.isNotEmpty) ...[
                _Section(
                  title: 'SON OLAYLAR',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: events
                        .map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                event,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ))
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (operations.isNotEmpty)
                _Section(
                  title: 'SON ÜRETİMLER',
                  child: Column(
                    children: operations
                        .map((operation) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OperationCard(
                                operation: operation,
                                status: _status(operation.status),
                                color: _statusColor(context, operation.status),
                              ),
                            ))
                        .toList(growable: false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.operation, required this.status, required this.color});

  final LiveOperation operation;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF08131C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withOpacity(.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  operation.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: operation.progress),
          const SizedBox(height: 10),
          Text(
            operation.currentStep ?? 'Üretim',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600),
          ),
          if (operation.agentId != null) ...[
            const SizedBox(height: 5),
            Text('Çalışan: ${operation.agentId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
          ],
          if (operation.message != null) ...[
            const SizedBox(height: 5),
            Text(operation.message!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF061019),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}
