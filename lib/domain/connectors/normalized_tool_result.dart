class NormalizedToolResult {
  const NormalizedToolResult({
    required this.success,
    required this.summary,
    this.data = const <String, dynamic>{},
    this.redacted = false,
  });

  final bool success;
  final String summary;
  final Map<String, dynamic> data;
  final bool redacted;
}
