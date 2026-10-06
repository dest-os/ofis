import '../../domain/security/permission_level.dart';
import '../../domain/security/security_decision.dart';
import '../../domain/security/security_principal.dart';

class AuthorizationService {
  SecurityDecision check({
    required SecurityPrincipal principal,
    required PermissionLevel requiredLevel,
    required String reason,
  }) {
    if (principal.level.allows(requiredLevel)) {
      return SecurityDecision(type: SecurityDecisionType.allow, reason: reason);
    }
    return SecurityDecision(type: SecurityDecisionType.deny, reason: 'Yetki yetersiz: $reason');
  }
}
