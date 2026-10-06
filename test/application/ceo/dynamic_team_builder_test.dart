import 'package:flutter_test/flutter_test.dart';
import 'package:ares/application/ceo/planning/dynamic_team_builder.dart';
import 'package:ares/domain/agents/agent_capability.dart';
import 'package:ares/domain/agents/agent_library_entry.dart';
import 'package:ares/domain/agents/agent_definition.dart';
import 'package:ares/domain/agents/agent_skill.dart';
import 'package:ares/domain/ceo/planning/ceo_execution_plan.dart';
import 'package:ares/domain/ceo/planning/plan_step.dart';
import 'package:ares/domain/tasks/task_priority.dart';

void main() {
  test('en uygun ajanı adım için seçer', () {
    final agent = AgentLibraryEntry(
      definition: const AgentDefinition(
        id: 'agent-code',
        name: 'Kod Ajanı',
        description: 'Kod',
        capabilities: <AgentCapability>[],
        skills: <AgentSkill>[AgentSkill(name: 'flutter')],
      ),
      version: '1.0.0',
      createdAt: DateTime(2026),
    );
    final plan = CeoExecutionPlan(
      id: 'p1',
      goal: 'Uygulama',
      priority: TaskPriority.normal,
      steps: const <PlanStep>[
        PlanStep(id: 's1', title: 'Kodla', description: 'Kod', requiredSkills: <String>['flutter']),
      ],
    );

    final team = DynamicTeamBuilder().build(plan: plan, candidates: <AgentLibraryEntry>[agent]);
    expect(team.members, hasLength(1));
    expect(team.members.single.agentId, 'agent-code');
    expect(team.members.single.score, 1.0);
  });
}
