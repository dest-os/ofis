import '../../domain/security/credential_reference.dart';

abstract interface class CredentialVault {
  Future<CredentialReference> createReference({
    required String id,
    required String provider,
    required String label,
  });

  Future<CredentialReference?> getReference(String id);

  Future<List<CredentialReference>> listReferences();

  Future<void> deactivate(String id);
}
