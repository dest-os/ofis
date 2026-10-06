import '../../domain/employees/employee.dart';
import '../../core/result/ares_result.dart';

abstract interface class EmployeeRepository {
  AresResult<void> save(Employee employee);
  AresResult<Employee?> findById(String id);
  List<Employee> getAll();
  AresResult<void> remove(String id);
}
