class AgentSkill {
  const AgentSkill({
    required this.id,
    required this.name,
    this.level = 0.5,
    this.verified = false,
  });

  final String id;
  final String name;
  final double level;
  final bool verified;

  AgentSkill copyWith({
    String? id,
    String? name,
    double? level,
    bool? verified,
  }) {
    return AgentSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      verified: verified ?? this.verified,
    );
  }
}
