import '../../../domain/agents/agent_library_entry.dart';
import '../../../domain/ceo/planning/ceo_execution_plan.dart';
import '../../../domain/ceo/planning/execution_team.dart';
import '../../../domain/ceo/planning/team_member.dart';

class DynamicTeamBuilder {
  ExecutionTeam build({
    required CeoExecutionPlan plan,
    required List<AgentLibraryEntry> candidates,
  }) {
    final members = <TeamMember>[];

    for (final step in plan.steps) {
      AgentLibraryEntry? best;
      var bestScore = -1.0;

      for (final candidate in candidates) {
        if (!candidate.definition.enabled) continue;
        final score = _score(step.requiredSkills, candidate);
        if (score > bestScore) {
          bestScore = score;
          best = candidate;
        }
      }

      if (best != null) {
        members.add(
          TeamMember(
            agentId: best.definition.id,
            role: best.definition.systemRole,
            stepId: step.id,
            score: bestScore,
          ),
        );
      }
    }

    return ExecutionTeam(members: members);
  }

  double _score(List<String> skills, AgentLibraryEntry candidate) {
    if (skills.isEmpty) return 1.0;
    var matched = 0;
    for (final required in skills) {
      if (candidate.definition.supportsSkill(required)) matched++;
    }
    return matched / skills.length;
  }
}
