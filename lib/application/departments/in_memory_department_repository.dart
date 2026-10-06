import '../../domain/departments/department.dart';
import 'department_repository.dart';

class InMemoryDepartmentRepository implements DepartmentRepository {
  final Map<String, Department> _items = {};

  @override
  Future<void> save(Department department) async {
    _items[department.id] = department;
  }

  @override
  Future<Department?> getById(String id) async => _items[id];

  @override
  Future<List<Department>> getAll() async => List.unmodifiable(_items.values);

  @override
  Future<List<Department>> getActive() async =>
      _items.values.where((department) => department.active).toList(growable: false);
}
