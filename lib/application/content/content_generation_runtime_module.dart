import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import '../runtime/production/runtime_module.dart';
import 'content_generation_orchestrator.dart';

/// Registers and exposes the video/general content runtime.
class ContentGenerationRuntimeModule implements RuntimeModule {
  /// Creates a content runtime module.
  const ContentGenerationRuntimeModule(this.orchestrator);

  /// Configured content orchestrator.
  final ContentGenerationOrchestrator orchestrator;

  @override
  String get name => 'Content Generation Runtime';

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  /// Generates a content package through the orchestrator.
  Future<ContentGenerationResult> generate({
    required ContentMode mode,
    required String request,
    String duration = '60 saniye',
    String style = 'modern, temiz ve ARES uyumlu',
    String platform = 'YouTube Shorts',
    String contentType = 'uygulama fikri dokümanı',
    void Function(String status)? onProgress,
  }) => orchestrator.generate(
        mode: mode,
        request: request,
        duration: duration,
        style: style,
        platform: platform,
        contentType: contentType,
        onProgress: onProgress,
      );
}
