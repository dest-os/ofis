import 'package:flutter/material.dart';

class AresAiCenterScreen extends StatelessWidget {
  const AresAiCenterScreen({super.key});
  @override Widget build(BuildContext context) {
    final cards = const [
      ('YEREL AI', 'Cihaz üzerinde çalışan modeller', 'LOCAL'),
      ('ÜCRETSİZ AI', 'Ücretsiz kullanım doğrulaması', 'FREE'),
      ('SINIRLI ÜCRETSİZ', 'Limitli ücretsiz sağlayıcılar', 'LIMITED FREE'),
      ('ÜCRETLİ AI', 'Kullanım öncesi İbrahim onayı zorunlu', 'APPROVAL'),
      ('AI RADAR', 'Yeni model ve API doğrulaması', 'RADAR'),
      ('API ANAHTARLARI', 'Credential Vault üzerinden güvenli erişim', 'VAULT'),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(title: const Text('ARES — SİSTEM & AI MERKEZİ'), backgroundColor: const Color(0xFF08131D)),
      body: GridView.builder(padding: const EdgeInsets.all(18), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.3), itemCount: cards.length, itemBuilder: (_, i) => Card(color: const Color(0xFF0A1722), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cards[i].$1, style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(cards[i].$2, style: const TextStyle(color: Colors.white70)), const Spacer(), Text(cards[i].$3, style: const TextStyle(color: Colors.white38))]))));
  }
}
