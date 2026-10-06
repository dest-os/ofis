import '../../domain/security/credential_reference.dart';

abstract interface class CredentialReferenceStore {
  void save(CredentialReference reference);
  CredentialReference? find(String id);
}

class InMemoryCredentialReferenceStore implements CredentialReferenceStore {
  final Map<String, CredentialReference> _items = {};

  @override
  void save(CredentialReference reference) => _items[reference.id] = reference;

  @override
  CredentialReference? find(String id) => _items[id];
}
