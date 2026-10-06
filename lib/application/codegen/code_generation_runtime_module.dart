import '../../domain/codegen/generation_result.dart';
import '../../domain/codegen/project_spec.dart';
import '../runtime/production/runtime_module.dart';
import 'code_generation_orchestrator.dart';

/// Code Generation Orchestrator'ı ARES üretim runtime'ına bağlayan modüldür.
class CodeGenerationRuntimeModule implements RuntimeModule {
  /// Creates a runtime module around an already configured orchestrator.
  CodeGenerationRuntimeModule(this.orchestrator);

  /// Configured orchestrator used by this runtime module.
  final CodeGenerationOrchestrator orchestrator;
  bool _started = false;

  /// Human-readable runtime module name.
  @override
  String get name => 'Code Generation Runtime';

  /// Whether the module has been started.
  bool get isStarted => _started;

  /// Generates a project through the configured orchestrator.
  Future<GenerationResult> generate(
    ProjectSpec spec, {
    void Function(String status)? onProgress,
  }) {
    if (!_started) {
      throw StateError('Code Generation Runtime henüz başlatılmadı.');
    }
    return orchestrator.generate(spec, onProgress: onProgress);
  }

  /// Starts the code-generation runtime.
  @override
  Future<void> start() async {
    _started = true;
  }

  /// Stops the code-generation runtime.
  @override
  Future<void> stop() async {
    _started = false;
  }
}
