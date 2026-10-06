import 'package:flutter/material.dart';

import '../../application/connectors/connector_registry.dart';
import '../../domain/connectors/connector_definition.dart';
import '../../domain/connectors/connector_status.dart';

class ConnectorCenterScreen extends StatelessWidget {
  const ConnectorCenterScreen({super.key, this.registry});

  final ConnectorRegistry? registry;

  @override
  Widget build(BuildContext context) {
    final items = registry?.all() ?? const <ConnectorDefinition>[];
    final connected = items.where((item) =>
        item.enabled &&
        (item.status == ConnectorStatus.healthy ||
            item.status == ConnectorStatus.degraded)).length;

    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('BAĞLAYICI MERKEZİ'),
        backgroundColor: const Color(0xFF08131D),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StatusCard(
              title: 'Bağlantı durumu',
              value: items.isEmpty
                  ? 'Henüz bağlayıcı yok'
                  : '$connected / ${items.length} bağlı',
              icon: items.isEmpty ? Icons.link_off : Icons.link,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _InfoCard(
                title: 'Kayıtlı bağlayıcı bulunamadı',
                text: 'Şu anda ARES içinde kayıtlı bir dış bağlayıcı yok. Bu nedenle dış servise bağlı bir işlem çalıştırılmıyor.',
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ConnectorCard(item: item),
                  )),
            const SizedBox(height: 4),
            const _InfoCard(
              title: 'Güvenlik',
              text: 'İzinsiz dış bağlantı yok. Bağlayıcılar izin, kimlik bilgisi ve güvenlik kuralları üzerinden çalışır.',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0A1722),
        child: ListTile(
          leading: Icon(icon, color: Colors.cyanAccent),
          title: Text(title, style: const TextStyle(color: Colors.white70)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 17)),
          ),
        ),
      );
}

class _ConnectorCard extends StatelessWidget {
  const _ConnectorCard({required this.item});
  final ConnectorDefinition item;

  String get status {
    if (!item.enabled || item.status == ConnectorStatus.disabled) return 'Kapalı';
    switch (item.status) {
      case ConnectorStatus.healthy:
        return 'Bağlı';
      case ConnectorStatus.degraded:
        return 'Bağlı • sınırlı';
      case ConnectorStatus.registered:
        return 'Kayıtlı • henüz bağlanmadı';
      case ConnectorStatus.unavailable:
        return 'Kullanılamıyor';
      case ConnectorStatus.disabled:
        return 'Kapalı';
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0A1722),
        child: ListTile(
          title: Text(item.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '$status${item.requiresCredential ? ' • güvenli kimlik bilgisi gerekir' : ''}',
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Icon(
            item.status == ConnectorStatus.healthy ? Icons.check_circle : Icons.info_outline,
            color: item.status == ConnectorStatus.healthy ? Colors.greenAccent : Colors.cyanAccent,
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0A1722),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.white70, height: 1.35)),
          ]),
        ),
      );
}
