import '../../domain/departments/department.dart';
import 'department_repository.dart';

class DepartmentService {
  final DepartmentRepository repository;

  DepartmentService(this.repository);

  Future<void> register(Department department) {
    return repository.save(department);
  }

  Future<List<Department>> activeDepartments() {
    return repository.getActive();
  }
}
