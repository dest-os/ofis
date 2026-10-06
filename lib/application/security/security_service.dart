import '../../domain/ai/ai_category.dart';
import '../../domain/security/permission_level.dart';
import '../../domain/security/risk_level.dart';
import '../../domain/security/security_decision.dart';
import '../../domain/security/security_principal.dart';
import 'risk_engine.dart';
import 'security_policy_service.dart';

class SecurityService {
  SecurityService({RiskEngine? riskEngine, SecurityPolicyService? policy})
      : _riskEngine = riskEngine ?? RiskEngine(),
        _policy = policy ?? SecurityPolicyService();

  final RiskEngine _riskEngine;
  final SecurityPolicyService _policy;

  SecurityDecision authorizeAction({
    required SecurityPrincipal principal,
    required PermissionLevel requiredLevel,
    required RiskLevel riskLevel,
    required String reason,
    bool externalWrite = false,
    bool touchesSensitiveData = false,
  }) {
    final risk = _riskEngine.assess(
      baseLevel: riskLevel,
      reason: reason,
      externalWrite: externalWrite,
      touchesSensitiveData: touchesSensitiveData,
    );
    return _policy.authorize(principal: principal, requiredLevel: requiredLevel, risk: risk);
  }

  SecurityDecision authorizeAi({required SecurityPrincipal principal, required AiCategory category}) =>
      _policy.authorizeAiCategory(principal: principal, category: category);
}
