class SecurityScope {
  final String userId;
  final Set<String> projectIds;
  final Set<String> agentIds;
  final Set<String> toolIds;

  const SecurityScope({
    required this.userId,
    this.projectIds = const {},
    this.agentIds = const {},
    this.toolIds = const {},
  });
}
