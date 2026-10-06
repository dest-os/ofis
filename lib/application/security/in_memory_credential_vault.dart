import '../../domain/security/credential_reference.dart';
import 'credential_vault.dart';

class InMemoryCredentialVault implements CredentialVault {
  final Map<String, CredentialReference> _items =
      <String, CredentialReference>{};

  @override
  Future<CredentialReference> createReference({
    required String id,
    required String provider,
    required String label,
  }) async {
    if (_items.containsKey(id)) {
      throw StateError('Credential referansı zaten mevcut: $id');
    }

    final reference = CredentialReference(
      id: id,
      provider: provider,
      label: label,
      createdAt: DateTime.now().toUtc(),
    );

    _items[id] = reference;
    return reference;
  }

  @override
  Future<CredentialReference?> getReference(String id) async => _items[id];

  @override
  Future<List<CredentialReference>> listReferences() async {
    return List<CredentialReference>.unmodifiable(_items.values);
  }

  @override
  Future<void> deactivate(String id) async {
    final current = _items[id];
    if (current == null) return;

    _items[id] = CredentialReference(
      id: current.id,
      provider: current.provider,
      label: current.label,
      createdAt: current.createdAt,
      active: false,
    );
  }
}
