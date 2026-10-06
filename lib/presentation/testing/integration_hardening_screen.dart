import 'package:flutter/material.dart';

class IntegrationHardeningScreen extends StatelessWidget {
  const IntegrationHardeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checks = <String>[
      'Modül sözleşmeleri',
      'Event Bus akışı',
      'Task ↔ Agent akışı',
      'CEO ↔ CIO akışı',
      'Memory ↔ Archive',
      'AI Gateway ve ücret kapısı',
      'Tool / Credential Vault',
      'Backup / Restore / Migration',
      'Offline / Online',
      'Güvenlik ve gizlilik',
      'Performans / kaynak kullanımı',
      'Recovery / crash dayanıklılığı',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050A10),
      appBar: AppBar(
        title: const Text('ARES V30 • Integration & Hardening'),
        backgroundColor: const Color(0xFF07131E),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: checks.length,
        itemBuilder: (context, index) => Card(
          color: const Color(0xFF0B1823),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.cyan.withValues(alpha: .12),
              child: Text('${index + 1}'),
            ),
            title: Text(checks[index], style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.pending_outlined, color: Colors.cyanAccent),
          ),
        ),
      ),
    );
  }
}
