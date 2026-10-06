import 'dart:async';
import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../core/result/ares_result.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import 'openai_compatible_transport.dart';

/// OpenAI-compatible adapter for a configured free or limited-free remote AI.
class FreeRemoteAiGatewayAdapter implements AresAiGateway {
  /// Creates a remote adapter. Blank [baseUrl] disables this provider.
  FreeRemoteAiGatewayAdapter({
    required this.baseUrl,
    required this.model,
    this.apiKey,
    AiHttpTransport? transport,
    this.timeout = const Duration(seconds: 90),
  }) : _transport = transport ?? const DartIoAiHttpTransport();

  /// Provider base URL.
  final String baseUrl;

  /// Provider model identifier.
  final String model;

  /// Optional runtime API key. It is never stored in source code by this adapter.
  final String? apiKey;

  /// Request timeout.
  final Duration timeout;

  final AiHttpTransport _transport;

  /// Whether enough runtime configuration exists to make a request.
  bool get isConfigured => baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  /// Calls the configured OpenAI-compatible endpoint.
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    if (!isConfigured) {
      return const AresFailure<AiResponse>('Ücretsiz uzak AI yapılandırılmamış.');
    }
    try {
      final headers = <String, String>{};
      final key = apiKey?.trim();
      if (key != null && key.isNotEmpty) {
        headers['Authorization'] = 'Bearer $key';
      }
      final response = await _transport.postJson(
        uri: _chatUri(baseUrl),
        headers: headers,
        timeout: timeout,
        body: <String, Object?>{
          'model': model,
          'temperature': 0,
          'messages': <Map<String, String>>[
            <String, String>{'role': 'user', 'content': request.instruction},
          ],
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AresFailure<AiResponse>(
          'Ücretsiz uzak AI HTTP ${response.statusCode}: ${_short(response.body, key)}',
        );
      }
      final decoded = jsonDecode(response.body);
      final content = _content(decoded);
      if (content == null || content.trim().isEmpty) {
        return const AresFailure<AiResponse>('Ücretsiz uzak AI boş cevap döndürdü.');
      }
      return AresSuccess<AiResponse>(
        AiResponse(
          text: content,
          modelName: decoded is Map && decoded['model'] is String
              ? decoded['model'] as String
              : model,
        ),
      );
    } on TimeoutException {
      return const AresFailure<AiResponse>('Ücretsiz uzak AI zaman aşımına uğradı.');
    } on FormatException catch (error) {
      return AresFailure<AiResponse>('Ücretsiz uzak AI geçersiz JSON döndürdü: ${error.message}');
    } catch (error) {
      return AresFailure<AiResponse>('Ücretsiz uzak AI bağlantısı başarısız: $error');
    }
  }

  Uri _chatUri(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.endsWith('/chat/completions')) return Uri.parse(value);
    if (value.endsWith('/v1')) return Uri.parse('$value/chat/completions');
    return Uri.parse('$value/v1/chat/completions');
  }

  String? _content(dynamic decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) return null;
    final message = choices.first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  String _short(String value, String? secret) {
    final trimmed = value.length > 500 ? '${value.substring(0, 500)}…' : value;
    final safeSecret = secret?.trim();
    if (safeSecret == null || safeSecret.isEmpty) return trimmed;
    return trimmed.replaceAll(safeSecret, '[GİZLİ]');
  }
}
