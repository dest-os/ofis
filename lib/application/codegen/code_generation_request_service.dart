import '../../domain/codegen/generation_result.dart';
import 'code_generation_runtime_module.dart';
import 'project_spec_from_request.dart';

/// UI ile Code Generation Runtime arasındaki uygulama katmanı facade'ıdır.
class CodeGenerationRequestService {
  /// Creates the facade from a configured runtime module and request converter.
  const CodeGenerationRequestService({
    required CodeGenerationRuntimeModule runtimeModule,
    ProjectSpecFromRequest specBuilder = const ProjectSpecFromRequest(),
  })  : _runtimeModule = runtimeModule,
        _specBuilder = specBuilder;

  final CodeGenerationRuntimeModule _runtimeModule;
  final ProjectSpecFromRequest _specBuilder;

  /// Converts a high-level request to [ProjectSpec] and starts generation.
  ///
  /// [onProgress] is forwarded to the orchestrator so the UI can show live
  /// Turkish status updates without accessing runtime internals.
  Future<GenerationResult> generate(
    String request, {
    void Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('İstek: ProjectSpec hazırlanıyor.');
      final spec = _specBuilder.build(request);
      onProgress?.call('İstek: ProjectSpec hazır.');
      if (!_runtimeModule.isStarted) {
        await _runtimeModule.start();
      }
      return _runtimeModule.generate(spec, onProgress: onProgress);
    } catch (error) {
      rethrow;
    }
  }
}
