import 'connector_status.dart';

class ConnectorHealth {
  const ConnectorHealth({
    required this.status,
    required this.checkedAt,
    this.message = '',
  });

  final ConnectorStatus status;
  final DateTime checkedAt;
  final String message;
}
