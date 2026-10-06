import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/domain/connectors/connector_definition.dart';
import 'package:dest_os_ares/domain/connectors/connector_kind.dart';
import 'package:dest_os_ares/domain/connectors/connector_request.dart';
import 'package:dest_os_ares/application/connectors/connector_permission_guard.dart';
import 'package:dest_os_ares/application/connectors/in_memory_connector_registry.dart';

void main() {
  test('kayıtsız bağlantı bulunamaz', () {
    final registry = InMemoryConnectorRegistry();
    expect(registry.find('yok'), isNull);
  });

  test('harici yazma işlemi onaysız çalışmaz', () {
    final guard = ConnectorPermissionGuard();
    final definition = ConnectorDefinition(
      id: 'github',
      name: 'GitHub',
      kind: ConnectorKind.github,
      supportsWrite: true,
    );
    final decision = guard.evaluate(
      definition: definition,
      request: const ConnectorRequest(
        connectorId: 'github',
        operation: 'write_file',
      ),
      userApproved: false,
    );
    expect(decision.type.name, 'requireApproval');
  });
}
