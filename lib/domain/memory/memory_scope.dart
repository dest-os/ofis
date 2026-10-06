enum MemoryScope {
  personal,
  project,
  company,
  task,
  session,
}

extension MemoryScopeX on MemoryScope {
  String get value => name.toUpperCase();
}
