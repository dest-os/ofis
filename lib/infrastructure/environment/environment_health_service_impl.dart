import 'dart:convert';
import 'dart:io';

import '../../application/environment/environment_health_service.dart';

/// Performs non-destructive health checks against configured ARES dependencies.
class DefaultEnvironmentHealthService implements EnvironmentHealthService {
  /// Creates the health checker.
  const DefaultEnvironmentHealthService({required this.localBaseUrl, required this.localModel, this.freeBaseUrl, this.freeModel, this.freeApiKey, this.ffmpegExecutable = 'ffmpeg'});

  /// Local OpenAI-compatible endpoint.
  final String localBaseUrl;
  /// Configured local model name.
  final String localModel;
  /// Optional free remote endpoint.
  final String? freeBaseUrl;
  /// Optional free remote model name.
  final String? freeModel;
  /// Optional API key for the free remote endpoint.
  final String? freeApiKey;
  /// Local ffmpeg executable name.
  final String ffmpegExecutable;

  @override
  Future<EnvironmentHealth> check() async {
    final local = await _checkAi(localBaseUrl, localModel, 'Yerel AI');
    final free = freeBaseUrl == null || freeBaseUrl!.trim().isEmpty
        ? const DependencyHealth(name: 'Free AI', ready: false, message: 'Yapılandırılmamış. İsteğe bağlı ücretsiz endpoint tanımlayın.')
        : await _checkAi(freeBaseUrl!, freeModel ?? '', 'Free AI', apiKey: freeApiKey);
    final ffmpeg = await _checkFfmpeg();
    return EnvironmentHealth(localAi: local, freeAi: free, ffmpeg: ffmpeg);
  }

  Future<DependencyHealth> _checkAi(String baseUrl, String model, String name, {String? apiKey}) async {
    if (baseUrl.trim().isEmpty || model.trim().isEmpty) {
      return DependencyHealth(name: name, ready: false, message: 'Adres veya model adı eksik.');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
      final endpoints = <String>['$root/api/tags', '$root/v1/models'];
      for (final endpoint in endpoints) {
        try {
          final uri = Uri.parse(endpoint);
          final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
          if (apiKey != null && apiKey.trim().isNotEmpty) {
            request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey.trim()}');
          }
          final response = await request.close().timeout(const Duration(seconds: 5));
          final body = await response.transform(utf8.decoder).join();
          if (response.statusCode >= 200 && response.statusCode < 300 && body.isNotEmpty) {
            final modelPresent = body.toLowerCase().contains(model.toLowerCase());
            return DependencyHealth(name: name, ready: modelPresent, message: modelPresent ? 'Hazır • model: $model' : 'Adres hazır ancak model listesinde $model bulunamadı.');
          }
        } catch (_) {
          // Try the next OpenAI-compatible health endpoint.
        }
      }
      return DependencyHealth(name: name, ready: false, message: 'Adrese erişilemiyor veya model listesi alınamıyor.');
    } finally {
      client.close(force: true);
    }
  }

  Future<DependencyHealth> _checkFfmpeg() async {
    try {
      final result = await Process.run(ffmpegExecutable, const <String>['-version'], runInShell: false).timeout(const Duration(seconds: 5));
      return DependencyHealth(name: 'ffmpeg', ready: result.exitCode == 0, message: result.exitCode == 0 ? 'Hazır.' : 'Kurulu ancak çalıştırılamadı.');
    } catch (_) {
      return const DependencyHealth(name: 'ffmpeg', ready: false, message: 'Kurulu değil. Video paketi yine üretilebilir; gerçek render için kurulum gerekir.');
    }
  }
}
