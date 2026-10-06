import 'package:flutter/material.dart';

class AresAiCenterScreen extends StatelessWidget {
  const AresAiCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <(String, String, String)>[
      ('YEREL AI', 'Cihaz üzerinde çalışan modeller', 'LOCAL'),
      ('UCRETSIZ AI', 'Ucretsiz kullanim dogrulamasi', 'FREE'),
      ('SINIRLI UCRETSIZ', 'Limitli ucretsiz saglayicilar', 'LIMITED FREE'),
      ('UCRETLI AI', 'Kullanim oncesi Ibrahim onayi zorunlu', 'APPROVAL'),
      ('AI RADAR', 'Guvenli aday katalogu', 'RADAR'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('AI MERKEZI'),
        backgroundColor: const Color(0xFF08131D),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            color: const Color(0xFF0A1722),
            child: ListTile(
              title: Text(card.$1, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              subtitle: Text(card.$2, style: const TextStyle(color: Colors.white70)),
              trailing: Text(card.$3, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ),
          );
        },
      ),
    );
  }
}
