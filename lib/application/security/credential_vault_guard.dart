import '../../domain/security/security_decision.dart';

class CredentialVaultGuard {
  const CredentialVaultGuard();

  SecurityDecision allowSecretAccess({required String referenceId, required bool authorized}) {
    if (referenceId.trim().isEmpty) {
      return const SecurityDecision(type: SecurityDecisionType.deny, reason: 'Credential referansı boş olamaz.');
    }
    if (!authorized) {
      return const SecurityDecision(type: SecurityDecisionType.deny, reason: 'Credential erişimi yetkisiz.');
    }
    return const SecurityDecision(type: SecurityDecisionType.allow, reason: 'Credential yalnızca referans üzerinden kullanılabilir.');
  }
}
