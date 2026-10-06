import 'agent_definition.dart';

class AgentLibraryEntry {
  const AgentLibraryEntry({
    required this.definition,
    required this.version,
    required this.createdAt,
    this.source = 'ARES',
    this.tags = const <String>[],
  });

  final AgentDefinition definition;
  final String version;
  final DateTime createdAt;
  final String source;
  final List<String> tags;
}
