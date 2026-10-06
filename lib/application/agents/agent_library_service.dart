import '../../domain/agents/agent_capability.dart';
import '../../domain/agents/agent_definition.dart';
import '../../domain/agents/agent_library_entry.dart';
import '../../domain/agents/agent_skill.dart';
import 'agent_library_repository.dart';

class AgentLibraryService {
  AgentLibraryService(this._repository);

  final AgentLibraryRepository _repository;

  Future<AgentLibraryEntry> register({
    required String id,
    required String name,
    required String description,
    required List<AgentCapability> capabilities,
    required List<AgentSkill> skills,
    String systemRole = 'worker',
    String version = '1.0.0',
    List<String> tags = const <String>[],
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Ajan adı boş olamaz.');
    }

    final entry = AgentLibraryEntry(
      definition: AgentDefinition(
        id: id,
        name: name.trim(),
        description: description.trim(),
        capabilities: List<AgentCapability>.unmodifiable(capabilities),
        skills: List<AgentSkill>.unmodifiable(skills),
        systemRole: systemRole,
      ),
      version: version,
      createdAt: DateTime.now().toUtc(),
      tags: List<String>.unmodifiable(tags),
    );

    await _repository.save(entry);
    return entry;
  }

  Future<List<AgentLibraryEntry>> find(String query) {
    return _repository.search(query);
  }

  Future<AgentLibraryEntry?> get(String id) {
    return _repository.getById(id);
  }

  Future<void> remove(String id) {
    return _repository.remove(id);
  }
}
