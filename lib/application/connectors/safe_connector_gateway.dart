import '../../domain/connectors/connector_result.dart';
import '../../domain/connectors/connector_request.dart';
import 'connector_gateway.dart';
import 'connector_permission_guard.dart';
import 'connector_registry.dart';
import 'credential_reference_store.dart';
import 'quota_guard.dart';

class SafeConnectorGateway implements ConnectorGateway {
  SafeConnectorGateway({
    required this.registry,
    required this.permissionGuard,
    required this.credentialStore,
    required this.quotaGuard,
  });

  final ConnectorRegistry registry;
  final ConnectorPermissionGuard permissionGuard;
  final CredentialReferenceStore credentialStore;
  final QuotaGuard quotaGuard;

  @override
  Future<ConnectorResult> execute(ConnectorRequest request) async {
    final definition = registry.find(request.connectorId);
    if (definition == null) {
      return const ConnectorResult(
        success: false,
        statusCode: 404,
        error: 'Bağlantı kayıtlı değil.',
      );
    }
    if (definition.requiresCredential &&
        credentialStore.find(request.credentialReferenceId ?? '') == null) {
      return const ConnectorResult(
        success: false,
        statusCode: 401,
        error: 'Credential referansı geçersiz.',
      );
    }
    final decision = permissionGuard.evaluate(
      definition: definition,
      request: request,
      userApproved: false,
    );
    if (decision.type != ConnectorDecisionType.allow) {
      return ConnectorResult(
        success: false,
        statusCode: decision.type == ConnectorDecisionType.requireApproval ? 428 : 403,
        error: decision.reason,
      );
    }
    return const ConnectorResult(
      success: true,
      statusCode: 200,
      data: <String, dynamic>{'status': 'gateway-ready'},
    );
  }
}
