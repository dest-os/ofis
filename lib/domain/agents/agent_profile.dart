import '../../core/ids/ares_id.dart';
import 'agent_role.dart';
import 'agent_status.dart';

class AgentProfile {
  const AgentProfile({
    required this.id,
    required this.name,
    required this.role,
    this.status = AgentStatus.active,
    this.skills = const <String>[],
  });

  final AresId id;
  final String name;
  final AgentRole role;
  final AgentStatus status;
  final List<String> skills;
}
