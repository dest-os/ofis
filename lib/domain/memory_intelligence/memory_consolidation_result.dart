class MemoryConsolidationResult {
  final int examined;
  final int retained;
  final int superseded;

  const MemoryConsolidationResult({
    required this.examined,
    required this.retained,
    required this.superseded,
  });
}
