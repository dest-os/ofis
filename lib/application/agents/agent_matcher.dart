import '../../domain/agents/agent_capability.dart';
import '../../domain/agents/agent_library_entry.dart';
import '../../domain/tasks/task_contract.dart';

class AgentMatcher {
  AgentLibraryEntry? findBestMatch({
    required TaskContract contract,
    required List<AgentLibraryEntry> candidates,
  }) {
    AgentLibraryEntry? best;
    var bestScore = -1;

    for (final candidate in candidates) {
      if (!candidate.definition.enabled) continue;

      var score = 0;

      for (final skill in contract.requiredSkills) {
        if (candidate.definition.supportsSkill(skill)) {
          score += 30;
        }
      }

      for (final capability in contract.requiredCapabilities) {
        if (candidate.definition.supportsCapability(capability)) {
          score += 20;
        }
      }

      if (candidate.definition.systemRole == 'worker') {
        score += 5;
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }
}
