class MemoryQuery {
  final String text;
  final String? projectId;
  final int limit;
  final DateTime? at;

  const MemoryQuery({
    required this.text,
    this.projectId,
    this.limit = 10,
    this.at,
  });
}
