import '../../domain/agent_runtime/agent_context.dart';
import '../../domain/agent_runtime/agent_execution_contract.dart';

class AgentContextBuilder {
  const AgentContextBuilder();

  AgentContext build({
    required AgentExecutionContract contract,
    required String agentId,
    Map<String, Object?> memory = const <String, Object?>{},
    Map<String, Object?> archive = const <String, Object?>{},
  }) {
    return AgentContext(
      runId: contract.runId,
      taskId: contract.taskId,
      agentId: agentId,
      instruction: contract.instruction,
      memory: memory,
      archive: archive,
      metadata: contract.metadata,
    );
  }
}
