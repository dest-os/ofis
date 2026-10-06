import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/security/in_memory_credential_vault.dart';

void main() {
  test('vault yalnızca credential referansı saklar', () async {
    final vault = InMemoryCredentialVault();

    final reference = await vault.createReference(
      id: 'cred-1',
      provider: 'example-provider',
      label: 'Ana bağlantı',
    );

    expect(reference.id, 'cred-1');
    expect(reference.provider, 'example-provider');
    expect(reference.label, 'Ana bağlantı');
  });
}
