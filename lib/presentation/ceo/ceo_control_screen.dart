import 'package:flutter/material.dart';

import '../../application/ceo/ceo_brain_service.dart';
import '../../domain/ceo/ceo_intent.dart';

class CeoControlScreen extends StatefulWidget {
  const CeoControlScreen({super.key});

  @override
  State<CeoControlScreen> createState() => _CeoControlScreenState();
}

class _CeoControlScreenState extends State<CeoControlScreen> {
  final CeoBrainService _ceo = CeoBrainService();
  final TextEditingController _controller = TextEditingController();

  CeoIntent? _intent;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _understand() {
    final result = _ceo.understand(_controller.text);
    setState(() => _intent = result);
  }

  @override
  Widget build(BuildContext context) {
    final intent = _intent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARES • CEO Beyni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Görevi anlat',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'İbrahim’in isteği burada anlaşılır ve planlanır.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _understand,
            icon: const Icon(Icons.psychology_outlined),
            label: const Text('CEO Anla'),
          ),
          if (intent != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niyet: ${intent.type.name}'),
                    const SizedBox(height: 6),
                    Text('Öncelik: ${intent.priority}'),
                    const SizedBox(height: 6),
                    Text('Hedef: ${intent.goal ?? '-'}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
