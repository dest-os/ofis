import 'package:flutter/material.dart';

import '../../application/runtime/production/production_composition_root.dart';
import '../../domain/runtime/runtime_snapshot.dart';
import '../../domain/runtime/runtime_status.dart';

class ProductionRuntimeScreen extends StatefulWidget {
  const ProductionRuntimeScreen({super.key});

  @override
  State<ProductionRuntimeScreen> createState() => _ProductionRuntimeScreenState();
}

class _ProductionRuntimeScreenState extends State<ProductionRuntimeScreen> {
  final _root = ProductionCompositionRoot();
  RuntimeSnapshot? _snapshot;
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final runtime = _root.build();
      await runtime.start();
      if (!mounted) return;
      setState(() => _snapshot = runtime.snapshot());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusText(RuntimeStatus status) {
    switch (status) {
      case RuntimeStatus.running:
        return 'Çalışıyor';
      case RuntimeStatus.starting:
        return 'Başlıyor';
      case RuntimeStatus.stopped:
        return 'Durduruldu';
      case RuntimeStatus.degraded:
        return 'Sınırlı çalışıyor';
      case RuntimeStatus.stopping:
        return 'Durduruluyor';
      case RuntimeStatus.failed:
        return 'Hata';
    }
  }

  String _modeText(String mode) {
    switch (mode) {
      case 'online':
        return 'Çevrimiçi';
      case 'offline':
        return 'Çevrimdışı';
      case 'recovering':
        return 'Kurtarma';
      case 'safeMode':
        return 'Güvenli çalışma';
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('ÇALIŞMA SİSTEMİ'),
        backgroundColor: const Color(0xFF08131D),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatusCard(
            title: 'Sistem durumu',
            value: snapshot == null ? 'Hazır • henüz başlatılmadı' : _statusText(snapshot.status),
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'Çalışma biçimi',
            value: snapshot == null ? 'Hazır' : _modeText(snapshot.mode.name),
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'Devam eden işler',
            value: snapshot == null ? 'Kayıt yok' : '${snapshot.activeTasks}',
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'Çalışan görevli sayısı',
            value: snapshot == null ? 'Kayıt yok' : '${snapshot.activeAgents}',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _busy ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: Text(_busy ? 'BAŞLATILIYOR…' : 'SİSTEMİ BAŞLAT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0A1722),
        child: ListTile(
          title: Text(title, style: const TextStyle(color: Colors.white70)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 17)),
          ),
        ),
      );
}
