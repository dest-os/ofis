import '../../domain/connectors/connector_result.dart';
import '../../domain/connectors/connector_request.dart';

abstract interface class ConnectorGateway {
  Future<ConnectorResult> execute(ConnectorRequest request);
}
