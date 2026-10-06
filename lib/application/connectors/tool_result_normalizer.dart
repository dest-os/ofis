import '../../domain/connectors/normalized_tool_result.dart';
import '../../domain/connectors/connector_result.dart';

class ToolResultNormalizer {
  NormalizedToolResult normalize(ConnectorResult result) {
    if (!result.success) {
      return NormalizedToolResult(
        success: false,
        summary: result.error ?? 'Bağlantı işlemi başarısız.',
      );
    }
    return NormalizedToolResult(
      success: true,
      summary: 'Bağlantı işlemi tamamlandı.',
      data: result.data ?? const <String, dynamic>{},
    );
  }
}
