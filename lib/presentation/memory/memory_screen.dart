import 'package:flutter/material.dart';

import '../../application/memory/in_memory_memory_repository.dart';
import '../../application/memory/memory_service.dart';
import '../../domain/memory/memory_scope.dart';
import '../../domain/memory/memory_type.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final MemoryService _service = MemoryService(
    InMemoryMemoryRepository(),
  );

  final TextEditingController _controller = TextEditingController();
  List<String> _results = const <String>[];

  Future<void> _remember() async {
    if (_controller.text.trim().isEmpty) return;

    await _service.remember(
      id: 'memory-${DateTime.now().microsecondsSinceEpoch}',
      content: _controller.text,
      type: MemoryType.preference,
      scope: MemoryScope.personal,
      source: 'user',
      tags: const <String>['user'],
    );

    _controller.clear();
    await _search('');
  }

  Future<void> _search(String query) async {
    final items = await _service.retrieve(query);
    if (!mounted) return;
    setState(() {
      _results = items.map((item) => item.content).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ARES • Hafıza')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Kişisel hafıza',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hatırla ve ara işlemlerinin ilk temel katmanı.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'ARES için hatırlanacak bilgi',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _remember,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Hatırla'),
          ),
          const SizedBox(height: 18),
          ..._results.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.memory_outlined),
                title: Text(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
