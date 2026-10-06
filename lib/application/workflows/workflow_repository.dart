import '../../domain/workflows/workflow_definition.dart';

abstract class WorkflowRepository {
  Future<void> save(WorkflowDefinition workflow);
  Future<WorkflowDefinition?> getById(String id);
  Future<List<WorkflowDefinition>> list();
}
