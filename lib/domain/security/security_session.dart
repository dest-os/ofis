class SecuritySession {
  final String id;
  final String principalId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool active;

  const SecuritySession({
    required this.id,
    required this.principalId,
    required this.createdAt,
    required this.expiresAt,
    this.active = true,
  });

  bool isValid(DateTime now) => active && now.isBefore(expiresAt);
}
