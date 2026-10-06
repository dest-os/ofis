class CredentialReference {
  const CredentialReference({
    required this.id,
    required this.provider,
    required this.label,
    required this.createdAt,
    this.active = true,
  });

  final String id;
  final String provider;
  final String label;
  final DateTime createdAt;
  final bool active;
}
