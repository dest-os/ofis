import '../../domain/connectors/connector_decision_type.dart';
import '../../domain/connectors/connector_decision.dart';
import '../../domain/connectors/connector_definition.dart';
import '../../domain/connectors/connector_request.dart';
import '../../domain/connectors/connector_status.dart';

class ConnectorPermissionGuard {
  ConnectorDecision evaluate({
    required ConnectorDefinition definition,
    required ConnectorRequest request,
    required bool userApproved,
  }) {
    if (!definition.enabled || definition.status == ConnectorStatus.disabled) {
      return const ConnectorDecision(
        type: ConnectorDecisionType.deny,
        reason: 'Bağlantı devre dışı.',
      );
    }
    if (!definition.supportsRead && !definition.supportsWrite) {
      return const ConnectorDecision(
        type: ConnectorDecisionType.deny,
        reason: 'Bağlantı operasyon desteklemiyor.',
      );
    }
    final isWrite = request.operation.toLowerCase().contains('write') ||
        request.operation.toLowerCase().contains('create') ||
        request.operation.toLowerCase().contains('delete') ||
        request.operation.toLowerCase().contains('update');
    if (isWrite && !definition.supportsWrite) {
      return const ConnectorDecision(
        type: ConnectorDecisionType.deny,
        reason: 'Yazma işlemi desteklenmiyor.',
      );
    }
    if (definition.requiresCredential && request.credentialReferenceId == null) {
      return const ConnectorDecision(
        type: ConnectorDecisionType.deny,
        reason: 'Credential referansı gerekiyor.',
      );
    }
    if (isWrite && !userApproved) {
      return const ConnectorDecision(
        type: ConnectorDecisionType.requireApproval,
        reason: 'Harici yazma işlemi için onay gerekiyor.',
      );
    }
    return const ConnectorDecision(
      type: ConnectorDecisionType.allow,
      reason: 'Bağlantı güvenlik koşullarını sağladı.',
    );
  }
}
