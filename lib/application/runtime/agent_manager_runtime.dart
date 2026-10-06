import '../../domain/agents/agent_profile.dart';

abstract interface class AgentManagerRuntime {
  Future<AgentProfile?> acquireWorker({required String taskId});
  Future<void> releaseWorker({required String taskId, required String agentId});
}
