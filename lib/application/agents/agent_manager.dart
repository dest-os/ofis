import '../../domain/agents/agent_profile.dart';
import '../../domain/tasks/task_role.dart';

class AgentManager {
  final Map<String, AgentProfile> _agents = <String, AgentProfile>{};

  Future<void> register(AgentProfile agent) async {
    if (_agents.containsKey(agent.id.value)) {
      throw StateError('Ajan zaten kayıtlı: ${agent.id}');
    }
    _agents[agent.id.value] = agent;
  }

  Future<AgentProfile?> getById(String id) async => _agents[id];

  Future<List<AgentProfile>> activeAgents() async {
    return List<AgentProfile>.unmodifiable(
      _agents.values.where((agent) => agent.status.name == 'active'),
    );
  }

  Future<AgentProfile> selectForRole(TaskRole role) async {
    final active = await activeAgents();

    for (final agent in active) {
      if (_supportsRole(agent, role)) {
        return agent;
      }
    }

    throw StateError('Uygun aktif ajan bulunamadı: ${role.value}');
  }

  bool _supportsRole(AgentProfile agent, TaskRole role) {
    final roleText = role.name.toLowerCase();
    return agent.skills.any(
      (skill) => skill.toLowerCase() == roleText,
    );
  }
}
