import '../../domain/tools/tool_definition.dart';

abstract interface class ToolRegistry {
  Future<void> register(ToolDefinition definition);
  Future<ToolDefinition?> getById(String id);
  Future<List<ToolDefinition>> getAll();
  Future<void> remove(String id);
}
