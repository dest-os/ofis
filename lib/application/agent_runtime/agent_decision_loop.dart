import '../../domain/agent_runtime/agent_context.dart';
import '../../domain/agent_runtime/agent_decision.dart';

abstract interface class AgentDecisionLoop {
  Future<AgentDecision> decide(AgentContext context);
}

class SafeAgentDecisionLoop implements AgentDecisionLoop {
  const SafeAgentDecisionLoop();

  @override
  Future<AgentDecision> decide(AgentContext context) async {
    return const AgentDecision(
      action: 'RESPOND',
      reason: 'V18 güvenli varsayılan karar yolu.',
    );
  }
}
