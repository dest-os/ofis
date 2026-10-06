import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import 'content_generation_runtime_module.dart';

/// UI ile video/genel içerik runtime'ı arasındaki facade'dır.
class ContentRequestService {
  /// Creates the facade from a registered runtime module.
  const ContentRequestService(this._runtime);
  final ContentGenerationRuntimeModule _runtime;

  /// Generates the requested content package.
  Future<ContentGenerationResult> generate({
    required ContentMode mode,
    required String request,
    String duration = '60 saniye',
    String style = 'modern, temiz ve ARES uyumlu',
    String platform = 'YouTube Shorts',
    String contentType = 'uygulama fikri dokümanı',
    void Function(String status)? onProgress,
  }) => _runtime.generate(
        mode: mode,
        request: request,
        duration: duration,
        style: style,
        platform: platform,
        contentType: contentType,
        onProgress: onProgress,
      );
}
