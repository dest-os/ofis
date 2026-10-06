import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/agents/agent_matcher.dart';
import 'package:dest_os_ares/domain/agents/agent_capability.dart';
import 'package:dest_os_ares/domain/agents/agent_definition.dart';
import 'package:dest_os_ares/domain/agents/agent_library_entry.dart';
import 'package:dest_os_ares/domain/agents/agent_skill.dart';
import 'package:dest_os_ares/domain/tasks/task_contract.dart';
import 'package:dest_os_ares/domain/tasks/task_priority.dart';

void main() {
  test('görev için yetenekli ajan seçilir', () {
    final codingAgent = AgentLibraryEntry(
      definition: AgentDefinition(
        id: 'coding',
        name: 'Kodlama',
        description: 'Kodlama',
        capabilities: <AgentCapability>[AgentCapability.coding],
        skills: <AgentSkill>[
          AgentSkill(id: 'coding', name: 'coding', level: 1.0),
        ],
      ),
      version: '1.0.0',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final researchAgent = AgentLibraryEntry(
      definition: AgentDefinition(
        id: 'research',
        name: 'Araştırma',
        description: 'Araştırma',
        capabilities: <AgentCapability>[AgentCapability.research],
        skills: <AgentSkill>[
          AgentSkill(id: 'research', name: 'research', level: 1.0),
        ],
      ),
      version: '1.0.0',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final contract = TaskContract(
      id: 'task',
      title: 'Kod yaz',
      description: 'Kod',
      priority: TaskPriority.normal,
      acceptanceCriteria: <String>['test'],
      requiredSkills: <String>['coding'],
      requiredCapabilities: <AgentCapability>[AgentCapability.coding],
    );

    final result = AgentMatcher().findBestMatch(
      contract: contract,
      candidates: <AgentLibraryEntry>[
        researchAgent,
        codingAgent,
      ],
    );

    expect(result?.definition.id, 'coding');
  });
}
