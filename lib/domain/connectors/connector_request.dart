class ConnectorRequest {
  const ConnectorRequest({
    required this.connectorId,
    required this.operation,
    this.parameters = const <String, dynamic>{},
    this.credentialReferenceId,
  });

  final String connectorId;
  final String operation;
  final Map<String, dynamic> parameters;
  final String? credentialReferenceId;
}
