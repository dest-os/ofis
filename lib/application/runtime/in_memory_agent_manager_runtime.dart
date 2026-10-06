import '../../domain/agents/agent_profile.dart';
import '../../domain/agents/agent_role.dart';
import '../../core/ids/ares_id.dart';
import 'agent_manager_runtime.dart';

class InMemoryAgentManagerRuntime implements AgentManagerRuntime {
  InMemoryAgentManagerRuntime({List<AgentProfile>? workers})
      : _workers = workers ?? const <AgentProfile>[];

  final List<AgentProfile> _workers;
  final Set<String> _busy = <String>{};

  @override
  Future<AgentProfile?> acquireWorker({required String taskId}) async {
    for (final worker in _workers) {
      if (_busy.add(worker.id.value)) return worker;
    }
    return null;
  }

  @override
  Future<void> releaseWorker({required String taskId, required String agentId}) async {
    _busy.remove(agentId);
  }
}
