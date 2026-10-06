class ReleaseManifest {
  final String version;
  final String buildNumber;
  final String channel;
  final String artifactType;
  final String integrityHash;
  final DateTime createdAt;
  final bool signed;

  const ReleaseManifest({
    required this.version,
    required this.buildNumber,
    required this.channel,
    required this.artifactType,
    required this.integrityHash,
    required this.createdAt,
    required this.signed,
  });
}
