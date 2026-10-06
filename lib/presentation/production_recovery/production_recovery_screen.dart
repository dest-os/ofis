import 'package:flutter/material.dart';

import '../../application/live_operations/live_operations_store.dart';
import '../../domain/live_operations/live_operation_status.dart';

class ProductionRecoveryScreen extends StatelessWidget {
  const ProductionRecoveryScreen({super.key, this.store, this.onRetry});

  final LiveOperationsStore? store;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final latest = _latestResult();
    final canRetry = onRetry != null;

    return Scaffold(
      backgroundColor: const Color(0xFF050A10),
      appBar: AppBar(
        title: const Text('ÜRETİM KURTARMA'),
        backgroundColor: const Color(0xFF071522),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ResultCard(latest: latest),
          const SizedBox(height: 12),
          const Card(
            color: Color(0xFF0A1722),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kurtarma işlemi yalnızca gerçek bir üretim kaydı ve gerçek bir yeniden deneme işlemi varsa başlatılabilir.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (canRetry)
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('YENİDEN DENE'),
              ),
            )
          else
            const Card(
              color: Color(0xFF0A1722),
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Colors.cyanAccent),
                title: Text('Yeniden deneme hazır değil', style: TextStyle(color: Colors.white)),
                subtitle: Text('Bu ekrana bağlı gerçek bir yeniden deneme işlemi bulunmuyor.', style: TextStyle(color: Colors.white60)),
              ),
            ),
        ],
      ),
    );
  }

  _ProductionResult? _latestResult() {
    final operations = store?.operations ?? const [];
    final finished = operations
        .where((item) => item.status == LiveOperationStatus.completed || item.status == LiveOperationStatus.failed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (finished.isEmpty) return null;
    final item = finished.first;
    return _ProductionResult(
      title: item.title,
      success: item.status == LiveOperationStatus.completed,
      message: item.message,
      time: item.updatedAt,
    );
  }
}

class _ProductionResult {
  const _ProductionResult({required this.title, required this.success, required this.message, required this.time});
  final String title;
  final bool success;
  final String message;
  final DateTime time;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.latest});
  final _ProductionResult? latest;

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return const Card(
        color: Color(0xFF0A1722),
        child: ListTile(
          leading: Icon(Icons.history, color: Colors.cyanAccent),
          title: Text('Son üretim', style: TextStyle(color: Colors.white)),
          subtitle: Text('Kayıt yok', style: TextStyle(color: Colors.white60)),
        ),
      );
    }
    return Card(
      color: const Color(0xFF0A1722),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Son üretim', style: TextStyle(color: latest!.success ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(latest!.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 5),
          Text(latest!.success ? 'Başarılı' : 'Hata', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 5),
          Text(latest!.message, style: const TextStyle(color: Colors.white60, height: 1.3)),
        ]),
      ),
    );
  }
}
