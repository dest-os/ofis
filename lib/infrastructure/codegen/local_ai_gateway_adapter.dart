import 'dart:async';
import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../core/result/ares_result.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import 'openai_compatible_transport.dart';

/// OpenAI-compatible gateway adapter for local Ollama or LM Studio servers.
class LocalAiGatewayAdapter implements AresAiGateway {
  /// Creates a local AI adapter.
  LocalAiGatewayAdapter({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'qwen3:4b',
    AiHttpTransport? transport,
    this.timeout = const Duration(seconds: 90),
  }) : _transport = transport ?? const DartIoAiHttpTransport();

  /// Base URL of Ollama or LM Studio.
  final String baseUrl;

  /// Local model identifier.
  final String model;

  /// Request timeout.
  final Duration timeout;

  final AiHttpTransport _transport;

  /// Calls the local OpenAI-compatible chat endpoint.
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    try {
      final response = await _transport.postJson(
        uri: _chatUri(baseUrl),
        headers: const <String, String>{},
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
          'Yerel AI HTTP ${response.statusCode}: ${_short(response.body)}',
        );
      }
      final decoded = jsonDecode(response.body);
      final content = _content(decoded);
      if (content == null || content.trim().isEmpty) {
        return const AresFailure<AiResponse>('Yerel AI boş cevap döndürdü.');
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
      return const AresFailure<AiResponse>('Yerel AI zaman aşımına uğradı.');
    } on FormatException catch (error) {
      return AresFailure<AiResponse>('Yerel AI geçersiz JSON döndürdü: ${error.message}');
    } catch (error) {
      return AresFailure<AiResponse>('Yerel AI bağlantısı başarısız: $error');
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
    if (content is String) return content;
    if (content is List) {
      return content.whereType<Map>().map((part) => part['text']).whereType<String>().join();
    }
    return null;
  }

  String _short(String value) => value.length > 500 ? '${value.substring(0, 500)}…' : value;
}
