import '../../domain/projects/project.dart';
import '../../domain/projects/project_status.dart';

abstract interface class ProjectRepository {
  Future<void> save(Project project);
  Future<Project?> getById(String id);
  Future<List<Project>> getAll();
  Future<List<Project>> getByStatus(ProjectStatus status);
}
