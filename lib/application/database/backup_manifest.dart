class BackupManifest {
  const BackupManifest({
    required this.id,
    required this.schemaVersion,
    required this.createdAt,
    required this.entityCount,
    required this.integrityHash,
  });

  final String id;
  final int schemaVersion;
  final DateTime createdAt;
  final int entityCount;
  final String integrityHash;
}
