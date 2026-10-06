import 'package:flutter/material.dart';

class ProductionReleaseScreen extends StatelessWidget {
  const ProductionReleaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checks = <String>[
      'Temel dosyalar',
      'Güvenlik kontrolleri',
      'Yedek ve geri yükleme',
      'Ücretli AI onay kapısı',
      'Yerel AI kontrolü',
      'Tablet son kontrolü',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050A10),
      appBar: AppBar(
        title: const Text('ÜRETİM YAYIN DURUMU'),
        backgroundColor: const Color(0xFF07131E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            color: Color(0xFF0A1722),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bu ekran son yayın hazırlığını sade biçimde gösterir. Bu oturumda yayın doğrulaması çalıştırılmadı; bu nedenle sonuçlar başarı olarak gösterilmez.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ),
          SizedBox(height: 12),
          ...checks.map((title) => _ReleaseCard(title: title)),
        ],
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => const Card(
        color: Color(0xFF0B1823),
        child: ListTile(
          leading: Icon(Icons.help_outline, color: Colors.orangeAccent),
          title: Text(title, style: TextStyle(color: Colors.white)),
          subtitle: Text('Doğrulama çalıştırılmadı', style: TextStyle(color: Colors.white60)),
        ),
      );
}
