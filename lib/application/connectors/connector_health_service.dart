import '../../domain/connectors/connector_definition.dart';
import '../../domain/connectors/connector_health.dart';
import '../../domain/connectors/connector_status.dart';

class ConnectorHealthService {
  ConnectorHealth check(ConnectorDefinition definition, DateTime now) {
    if (!definition.enabled) {
      return ConnectorHealth(
        status: ConnectorStatus.disabled,
        checkedAt: now,
        message: 'Bağlantı devre dışı.',
      );
    }
    return ConnectorHealth(
      status: definition.status,
      checkedAt: now,
      message: 'Kayıtlı bağlantı durumu kontrol edildi.',
    );
  }
}
