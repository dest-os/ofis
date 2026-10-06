enum MemoryType {
  fact,
  preference,
  instruction,
  conversation,
  project,
  company,
  decision,
}

extension MemoryTypeX on MemoryType {
  String get value => name.toUpperCase();
}
