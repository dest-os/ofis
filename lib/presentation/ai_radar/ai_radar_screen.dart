import 'package:flutter/material.dart';

import '../../application/ai_radar/ai_radar_service.dart';
import '../../domain/ai_radar/ai_radar_candidate.dart';

class AiRadarScreen extends StatelessWidget {
  const AiRadarScreen({super.key, this.service = const AiRadarService()});

  final AiRadarService service;

  @override
  Widget build(BuildContext context) {
    final candidates = service.catalog();
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('AI RADAR'),
        backgroundColor: const Color(0xFF08131D),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Yapay zekâ adayları',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bu liste güvenli, önceden tanımlı adaylardan oluşur. Ücretli bir model otomatik açılmaz.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111B23),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(.18)),
              ),
              child: const Text(
                'Çevrimiçi tarama yapılmadı. İnternet olmasa da güvenli katalog gösterilir. Kullanım koşulları ve ücretsiz limitler sağlayıcı tarafından değiştirilebilir.',
                style: TextStyle(color: Colors.white60, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
            for (final candidate in candidates) ...[
              _CandidateCard(candidate: candidate),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final AiRadarCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A1722),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(candidate.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            ),
            _Tag(text: candidate.typeLabel),
          ]),
          const SizedBox(height: 9),
          Text(candidate.description, style: const TextStyle(color: Colors.white70, height: 1.35)),
          if (candidate.model != null) ...[
            const SizedBox(height: 8),
            Text('Model: ${candidate.model}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.cyanAccent)),
          ],
          if (candidate.address != null) ...[
            const SizedBox(height: 4),
            Text('Adres: ${candidate.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
          ],
          const SizedBox(height: 10),
          const Text('Durum: Ayarlarda yapılandırılabilir', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(candidate.configurationHint, style: const TextStyle(color: Colors.white54, height: 1.3)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showDetails(context, candidate),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Adayı incele / Ayarlara geç'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showDetails(BuildContext context, AiRadarCandidate candidate) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(candidate.name),
        content: Text(
          '${candidate.configurationHint}\n\n'
          'Bu ekran adayı otomatik etkinleştirmez. Kullanmak için Sistem & API Ayarları bölümünde kendiniz yapılandırmanız gerekir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF103040), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
      );
}
