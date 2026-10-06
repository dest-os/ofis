class MemoryRetrievalPolicy {
  final bool archiveFirst;
  final bool projectIsolation;
  final int maxResults;

  const MemoryRetrievalPolicy({
    this.archiveFirst = true,
    this.projectIsolation = true,
    this.maxResults = 10,
  });
}
