import 'agent_capability.dart';
import 'agent_skill.dart';

class AgentDefinition {
  const AgentDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.capabilities,
    required this.skills,
    this.systemRole = 'worker',
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final List<AgentCapability> capabilities;
  final List<AgentSkill> skills;
  final String systemRole;
  final bool enabled;

  bool supportsSkill(String name) {
    final target = name.trim().toLowerCase();
    return skills.any((skill) => skill.name.toLowerCase() == target);
  }

  bool supportsCapability(AgentCapability capability) {
    return capabilities.contains(capability);
  }
}
