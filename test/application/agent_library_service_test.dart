import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/agents/agent_library_service.dart';
import 'package:dest_os_ares/application/agents/in_memory_agent_library_repository.dart';
import 'package:dest_os_ares/domain/agents/agent_capability.dart';
import 'package:dest_os_ares/domain/agents/agent_skill.dart';

void main() {
  test('ajan kütüphaneye kaydedilir ve bulunabilir', () async {
    final service = AgentLibraryService(
      InMemoryAgentLibraryRepository(),
    );

    await service.register(
      id: 'agent-1',
      name: 'Kodlama Ajanı',
      description: 'Kodlama görevleri',
      capabilities: const <AgentCapability>[AgentCapability.coding],
      skills: const <AgentSkill>[
        AgentSkill(
          id: 'skill-1',
          name: 'coding',
          level: 0.9,
          verified: true,
        ),
      ],
    );

    final result = await service.find('kodlama');

    expect(result, hasLength(1));
    expect(result.single.definition.id, 'agent-1');
  });
}
