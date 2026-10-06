import '../../domain/projects/project.dart';
import '../../domain/projects/project_status.dart';
import 'project_repository.dart';

class InMemoryProjectRepository implements ProjectRepository {
  final Map<String, Project> _items = {};

  @override
  Future<void> save(Project project) async {
    _items[project.id] = project;
  }

  @override
  Future<Project?> getById(String id) async => _items[id];

  @override
  Future<List<Project>> getAll() async => List.unmodifiable(_items.values);

  @override
  Future<List<Project>> getByStatus(ProjectStatus status) async =>
      _items.values.where((project) => project.status == status).toList(growable: false);
}
