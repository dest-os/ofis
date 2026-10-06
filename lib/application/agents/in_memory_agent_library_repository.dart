import '../../domain/agents/agent_library_entry.dart';
import 'agent_library_repository.dart';

class InMemoryAgentLibraryRepository implements AgentLibraryRepository {
  final Map<String, AgentLibraryEntry> _items =
      <String, AgentLibraryEntry>{};

  @override
  Future<void> save(AgentLibraryEntry entry) async {
    _items[entry.definition.id] = entry;
  }

  @override
  Future<AgentLibraryEntry?> getById(String id) async => _items[id];

  @override
  Future<List<AgentLibraryEntry>> getAll() async {
    return List<AgentLibraryEntry>.unmodifiable(_items.values);
  }

  @override
  Future<List<AgentLibraryEntry>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();

    return List<AgentLibraryEntry>.unmodifiable(
      _items.values.where(
        (entry) =>
            entry.definition.name.toLowerCase().contains(normalized) ||
            entry.definition.description
                .toLowerCase()
                .contains(normalized) ||
            entry.tags.any(
              (tag) => tag.toLowerCase().contains(normalized),
            ),
      ),
    );
  }

  @override
  Future<void> remove(String id) async {
    _items.remove(id);
  }
}
