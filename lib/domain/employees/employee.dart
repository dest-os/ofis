import '../../core/ids/ares_id.dart';
import '../agents/agent_role.dart';
import 'employee_skill.dart';
import 'employee_status.dart';

class Employee {
  final AresId id;
  final String name;
  final AgentRole role;
  final EmployeeStatus status;
  final List<EmployeeSkill> skills;
  final DateTime createdAt;
  final bool permanent;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.skills,
    required this.createdAt,
    this.permanent = false,
  });

  bool get isAvailable => status == EmployeeStatus.active;

  double skillScore(String skillId) {
    for (final skill in skills) {
      if (skill.id == skillId) return skill.proficiency;
    }
    return 0;
  }

  Employee withStatus(EmployeeStatus nextStatus) {
    return Employee(
      id: id,
      name: name,
      role: role,
      status: nextStatus,
      skills: List.unmodifiable(skills),
      createdAt: createdAt,
      permanent: permanent,
    );
  }
}
