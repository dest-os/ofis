import 'connector_kind.dart';
import 'connector_status.dart';

class ConnectorDefinition {
  const ConnectorDefinition({
    required this.id,
    required this.name,
    required this.kind,
    this.status = ConnectorStatus.registered,
    this.enabled = true,
    this.requiresCredential = false,
    this.supportsRead = true,
    this.supportsWrite = false,
  });

  final String id;
  final String name;
  final ConnectorKind kind;
  final ConnectorStatus status;
  final bool enabled;
  final bool requiresCredential;
  final bool supportsRead;
  final bool supportsWrite;
}
