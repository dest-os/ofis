import '../../domain/connectors/connector_definition.dart';
import 'connector_registry.dart';

class InMemoryConnectorRegistry implements ConnectorRegistry {
  final Map<String, ConnectorDefinition> _items = {};

  @override
  void register(ConnectorDefinition definition) => _items[definition.id] = definition;

  @override
  ConnectorDefinition? find(String id) => _items[id];

  @override
  List<ConnectorDefinition> all() => List.unmodifiable(_items.values);
}
