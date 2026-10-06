import '../../domain/agents/agent_library_entry.dart';

abstract interface class AgentLibraryRepository {
  Future<void> save(AgentLibraryEntry entry);
  Future<AgentLibraryEntry?> getById(String id);
  Future<List<AgentLibraryEntry>> getAll();
  Future<List<AgentLibraryEntry>> search(String query);
  Future<void> remove(String id);
}
