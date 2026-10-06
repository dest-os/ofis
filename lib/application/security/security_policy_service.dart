import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_category.dart';
import '../../domain/security/risk_assessment.dart';
import '../../domain/security/risk_level.dart';
import '../../domain/security/security_decision.dart';
import '../../domain/security/security_principal.dart';
import '../../domain/security/permission_level.dart';
import 'authorization_service.dart';

class SecurityPolicyService {
  SecurityPolicyService({AuthorizationService? authorization}) : _authorization = authorization ?? AuthorizationService();
  final AuthorizationService _authorization;

  SecurityDecision authorize({
    required SecurityPrincipal principal,
    required PermissionLevel requiredLevel,
    required RiskAssessment risk,
  }) {
    final permission = _authorization.check(
      principal: principal,
      requiredLevel: requiredLevel,
      reason: risk.reason,
    );
    if (!permission.allowed) return permission;
    if (risk.level.requiresApproval) {
      return const SecurityDecision(type: SecurityDecisionType.requireApproval, reason: 'Risk seviyesi kullanıcı onayı gerektiriyor.');
    }
    return permission;
  }

  SecurityDecision authorizeAiCategory({required SecurityPrincipal principal, required AiCategory category}) {
    if (category == AiCategory.paid || category == AiCategory.unknown) {
      if (!principal.isFounder) {
        return const SecurityDecision(type: SecurityDecisionType.requireApproval, reason: 'Ücretli veya bilinmeyen AI yalnızca İbrahim onayıyla kullanılabilir.');
      }
      return const SecurityDecision(type: SecurityDecisionType.requireApproval, reason: 'Ücretli/bilinmeyen AI için açık İbrahim onayı gereklidir.');
    }
    return const SecurityDecision(type: SecurityDecisionType.allow, reason: 'AI maliyet sınıfı otomatik çalışmaya uygundur.');
  }
}
