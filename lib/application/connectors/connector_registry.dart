import '../../domain/connectors/connector_definition.dart';

abstract interface class ConnectorRegistry {
  void register(ConnectorDefinition definition);
  ConnectorDefinition? find(String id);
  List<ConnectorDefinition> all();
}
