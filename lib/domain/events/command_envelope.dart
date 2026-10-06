class CommandEnvelope {
  const CommandEnvelope({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.source,
    this.target,
    this.payload = const <String, Object?>{},
    this.requiresApproval = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String source;
  final String? target;
  final Map<String, Object?> payload;
  final bool requiresApproval;
}
