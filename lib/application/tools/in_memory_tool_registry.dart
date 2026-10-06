import '../../domain/tools/tool_definition.dart';
import 'tool_registry.dart';

class InMemoryToolRegistry implements ToolRegistry {
  final Map<String, ToolDefinition> _items = <String, ToolDefinition>{};

  @override
  Future<void> register(ToolDefinition definition) async {
    if (_items.containsKey(definition.id)) {
      throw StateError('Araç zaten kayıtlı: ${definition.id}');
    }
    _items[definition.id] = definition;
  }

  @override
  Future<ToolDefinition?> getById(String id) async => _items[id];

  @override
  Future<List<ToolDefinition>> getAll() async {
    return List<ToolDefinition>.unmodifiable(_items.values);
  }

  @override
  Future<void> remove(String id) async {
    _items.remove(id);
  }
}
