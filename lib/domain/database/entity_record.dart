class EntityRecord {
  const EntityRecord({
    required this.id,
    required this.entityType,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
  });

  final String id;
  final String entityType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, Object?> data;
}
