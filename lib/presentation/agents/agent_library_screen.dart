import 'package:flutter/material.dart';

import '../../application/agents/agent_library_service.dart';
import '../../application/agents/in_memory_agent_library_repository.dart';
import '../../domain/agents/agent_capability.dart';
import '../../domain/agents/agent_skill.dart';

class AgentLibraryScreen extends StatefulWidget {
  const AgentLibraryScreen({super.key});

  @override
  State<AgentLibraryScreen> createState() => _AgentLibraryScreenState();
}

class _AgentLibraryScreenState extends State<AgentLibraryScreen> {
  final AgentLibraryService _service = AgentLibraryService(
    InMemoryAgentLibraryRepository(),
  );

  List<String> _agents = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    await _service.register(
      id: 'agent-research-001',
      name: 'Araştırma Ajanı',
      description: 'Araştırma ve bilgi toplama görevleri için temel ajan.',
      capabilities: const <AgentCapability>[
        AgentCapability.research,
        AgentCapability.analysis,
      ],
      skills: const <AgentSkill>[
        AgentSkill(
          id: 'research',
          name: 'research',
          level: 0.90,
          verified: true,
        ),
        AgentSkill(
          id: 'analysis',
          name: 'analysis',
          level: 0.80,
          verified: true,
        ),
      ],
      tags: const <String>['araştırma', 'bilgi'],
    );

    await _refresh();
  }

  Future<void> _refresh() async {
    final entries = await _service.find('');
    if (!mounted) return;
    setState(() {
      _agents = entries
          .map(
            (entry) =>
                '${entry.definition.name} • v${entry.version}',
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARES • Ajan Kütüphanesi'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ajan kataloğu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajan tanımları, yetenekleri ve sürümleri burada tutulur.',
          ),
          const SizedBox(height: 16),
          ..._agents.map(
            (agent) => Card(
              child: ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: Text(agent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
