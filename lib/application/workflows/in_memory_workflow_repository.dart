import '../../domain/workflows/workflow_definition.dart';
import 'workflow_repository.dart';

class InMemoryWorkflowRepository implements WorkflowRepository {
  final Map<String, WorkflowDefinition> _items = {};

  @override
  Future<void> save(WorkflowDefinition workflow) async {
    _items[workflow.id] = workflow;
  }

  @override
  Future<WorkflowDefinition?> getById(String id) async => _items[id];

  @override
  Future<List<WorkflowDefinition>> list() async => List.unmodifiable(_items.values);
}
