import '../../domain/projects/project.dart';
import '../../domain/projects/project_status.dart';
import 'project_repository.dart';

class ProjectService {
  final ProjectRepository repository;

  ProjectService(this.repository);

  Future<void> create(Project project) async {
    if (project.name.trim().isEmpty) {
      throw ArgumentError('Proje adı boş olamaz.');
    }
    if (project.goal.trim().isEmpty) {
      throw ArgumentError('Proje hedefi boş olamaz.');
    }
    if (project.memoryNamespace.trim().isEmpty) {
      throw ArgumentError('Proje hafıza alanı boş olamaz.');
    }
    await repository.save(project);
  }

  Future<void> update(Project project) {
    return repository.save(project);
  }

  Future<Project?> get(String id) {
    return repository.getById(id);
  }

  Future<List<Project>> activeProjects() {
    return repository.getByStatus(ProjectStatus.active);
  }
}
