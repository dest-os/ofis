import '../../core/ids/ares_id.dart';

enum MemoryType {
  working,
  conversation,
  project,
  company,
  preference,
  instruction,
}

class MemoryEntry {
  const MemoryEntry({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  final AresId id;
  final String content;
  final MemoryType type;
  final DateTime createdAt;
}
