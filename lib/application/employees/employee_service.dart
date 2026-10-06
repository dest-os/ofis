import '../../core/ids/ares_id.dart';
import '../../core/result/ares_result.dart';
import '../../domain/agents/agent_role.dart';
import '../../domain/employees/employee.dart';
import '../../domain/employees/employee_skill.dart';
import '../../domain/employees/employee_status.dart';
import 'employee_repository.dart';

class EmployeeService {
  final EmployeeRepository repository;

  const EmployeeService({required this.repository});

  Employee createEmployee({
    required String name,
    required AgentRole role,
    required List<EmployeeSkill> skills,
    bool permanent = false,
  }) {
    final employee = Employee(
      id: AresId(DateTime.now().toUtc().microsecondsSinceEpoch.toString()),
      name: name,
      role: role,
      status: EmployeeStatus.created,
      skills: List.unmodifiable(skills),
      createdAt: DateTime.now().toUtc(),
      permanent: permanent,
    );
    repository.save(employee);
    return employee;
  }

  bool activate(String employeeId) {
    final result = repository.findById(employeeId);
    final employee = result is AresSuccess<Employee?> ? result.value : null;
    if (employee == null) return false;
    repository.save(employee.withStatus(EmployeeStatus.active));
    return true;
  }

  bool suspend(String employeeId) {
    final result = repository.findById(employeeId);
    if (result is! AresSuccess<Employee?>) return false;
    final employee = result.value;
    if (employee == null || employee.permanent) return false;
    repository.save(employee.withStatus(EmployeeStatus.suspended));
    return true;
  }

  List<Employee> availableEmployees() =>
      repository.getAll().where((employee) => employee.isAvailable).toList(growable: false);

  List<Employee> findBySkill(String skillId) => repository
      .getAll()
      .where((employee) => employee.isAvailable && employee.skillScore(skillId) > 0)
      .toList(growable: false);

  List<Employee> buildMinimumTeam(Iterable<String> requiredSkillIds) {
    final selected = <Employee>[];
    final remaining = requiredSkillIds.toSet();

    for (final employee in availableEmployees()) {
      final covers = employee.skills
          .where((skill) => remaining.contains(skill.id))
          .map((skill) => skill.id)
          .toList();
      if (covers.isEmpty) continue;
      selected.add(employee);
      remaining.removeAll(covers);
      if (remaining.isEmpty) break;
    }

    return List.unmodifiable(selected);
  }
}
