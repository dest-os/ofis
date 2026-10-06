import '../../core/result/ares_result.dart';
import '../../domain/employees/employee.dart';
import 'employee_repository.dart';

class InMemoryEmployeeRepository implements EmployeeRepository {
  final Map<String, Employee> _employees = {};

  @override
  AresResult<void> save(Employee employee) {
    _employees[employee.id.value] = employee;
    return const AresSuccess<void>(null);
  }

  @override
  AresResult<Employee?> findById(String id) {
    return AresSuccess<Employee?>(_employees[id]);
  }

  @override
  List<Employee> getAll() => List.unmodifiable(_employees.values);

  @override
  AresResult<void> remove(String id) {
    _employees.remove(id);
    return const AresSuccess<void>(null);
  }
}
