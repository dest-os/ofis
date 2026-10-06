import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal HTTP transport used by OpenAI-compatible local/free AI adapters.
abstract interface class AiHttpTransport {
  /// Sends a JSON POST request and returns status code plus response text.
  Future<AiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 90),
  });
}

/// HTTP response returned by [AiHttpTransport].
class AiHttpResponse {
  /// Creates an immutable HTTP response.
  const AiHttpResponse({required this.statusCode, required this.body});

  /// HTTP status code.
  final int statusCode;

  /// Raw response body.
  final String body;
}

/// Production transport backed by Dart's [HttpClient].
class DartIoAiHttpTransport implements AiHttpTransport {
  /// Creates the production HTTP transport.
  const DartIoAiHttpTransport();

  @override
  Future<AiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(timeout);
      return AiHttpResponse(statusCode: response.statusCode, body: responseBody);
    } finally {
      client.close(force: true);
    }
  }
}
