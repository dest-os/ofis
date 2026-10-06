class ConnectorResult {
  const ConnectorResult({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
  });

  final bool success;
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? error;
}
