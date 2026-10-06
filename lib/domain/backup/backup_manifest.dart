class BackupManifest {
  final String id;
  final String appVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final List<String> includedScopes;
  final bool encrypted;
  final String integrityHash;
  const BackupManifest({required this.id, required this.appVersion, required this.schemaVersion, required this.createdAt, required this.includedScopes, required this.encrypted, required this.integrityHash});
}
