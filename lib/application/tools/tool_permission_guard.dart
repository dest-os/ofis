import '../../domain/tools/tool_decision.dart';
import '../../domain/tools/tool_definition.dart';
import '../../domain/tools/tool_request.dart';

class ToolPermissionGuard {
  ToolDecision evaluate({
    required ToolDefinition definition,
    required ToolRequest request,
    required bool userApproved,
  }) {
    if (!definition.enabled) {
      return const ToolDecision(
        type: ToolDecisionType.deny,
        reason: 'Araç devre dışı.',
      );
    }

    if (definition.requiresCredential && !request.parameters.containsKey(
      'credential_reference_id',
    )) {
      return const ToolDecision(
        type: ToolDecisionType.deny,
        reason: 'Güvenli credential referansı gerekiyor.',
      );
    }

    if (definition.requiresApproval && !userApproved) {
      return const ToolDecision(
        type: ToolDecisionType.requireApproval,
        reason: 'Araç işlemi için kullanıcı onayı gerekiyor.',
      );
    }

    return const ToolDecision(
      type: ToolDecisionType.allow,
      reason: 'Araç çağrısı güvenlik koşullarını sağladı.',
    );
  }
}
