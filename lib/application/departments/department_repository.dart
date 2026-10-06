import '../../domain/departments/department.dart';

abstract interface class DepartmentRepository {
  Future<void> save(Department department);
  Future<Department?> getById(String id);
  Future<List<Department>> getAll();
  Future<List<Department>> getActive();
}
