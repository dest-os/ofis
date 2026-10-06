class TeamMember {
  const TeamMember({
    required this.agentId,
    required this.role,
    required this.stepId,
    required this.score,
  });

  final String agentId;
  final String role;
  final String stepId;
  final double score;
}
