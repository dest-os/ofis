import '../../codegen/code_generation_orchestrator.dart';
import '../../content/content_generation_orchestrator.dart';
import '../../content/content_request_service.dart';
import '../../content/content_generation_runtime_module.dart';
import '../../codegen/code_generation_request_service.dart';
import '../../codegen/code_generation_runtime_module.dart';
import '../../config/runtime_config.dart';
import 'production_runtime.dart';
import 'runtime_module_registry.dart';
import 'operational_runtime_module.dart';

/// Composes the ARES production runtime modules and their dependencies.
class ProductionCompositionRoot {
  /// Creates the production composition root.
  ProductionCompositionRoot({
    RuntimeConfig? config,
    CodeGenerationOrchestrator? codeGenerationOrchestrator,
    ContentGenerationOrchestrator? contentGenerationOrchestrator,
  })  : config = config ?? const RuntimeConfig(),
        _codeGenerationOrchestrator = codeGenerationOrchestrator,
        _contentGenerationOrchestrator = contentGenerationOrchestrator;

  /// Runtime configuration used by the production runtime.
  final RuntimeConfig config;
  final CodeGenerationOrchestrator? _codeGenerationOrchestrator;
  final ContentGenerationOrchestrator? _contentGenerationOrchestrator;
  CodeGenerationRuntimeModule? _codeGenerationRuntimeModule;
  ContentGenerationRuntimeModule? _contentGenerationRuntimeModule;

  /// Builds the production runtime and registers the configured modules.
  ProductionRuntime build() {
    final registry = RuntimeModuleRegistry();
    registry.register(OperationalRuntimeModule('Task Runtime'));
    registry.register(OperationalRuntimeModule('Agent Runtime'));
    registry.register(OperationalRuntimeModule('CEO Runtime'));
    registry.register(OperationalRuntimeModule('CIO Runtime'));
    registry.register(OperationalRuntimeModule('AI Gateway Runtime'));
    registry.register(OperationalRuntimeModule('Tool Gateway Runtime'));
    registry.register(OperationalRuntimeModule('Event Bus Runtime'));
    registry.register(OperationalRuntimeModule('Scheduler Runtime'));
    registry.register(OperationalRuntimeModule('Workflow Runtime'));
    registry.register(OperationalRuntimeModule('Android Runtime'));
    registry.register(OperationalRuntimeModule('Voice Runtime'));
    registry.register(OperationalRuntimeModule('Chat Runtime'));

    final orchestrator = _codeGenerationOrchestrator;
    if (orchestrator != null) {
      final module = CodeGenerationRuntimeModule(orchestrator);
      _codeGenerationRuntimeModule = module;
      registry.register(module);
    }

    final contentOrchestrator = _contentGenerationOrchestrator;
    if (contentOrchestrator != null) {
      final module = ContentGenerationRuntimeModule(contentOrchestrator);
      _contentGenerationRuntimeModule = module;
      registry.register(module);
    }

    registry.register(OperationalRuntimeModule('UI Projection Runtime'));
    return ProductionRuntime(config: config, modules: registry);
  }

  /// Creates the application entry point used by the code-generation UI.
  ///
  /// The returned service uses the same configured [CodeGenerationRuntimeModule]
  /// that the production composition root registers. If no orchestrator was
  /// supplied, an error is raised instead of silently bypassing the runtime.
  CodeGenerationRequestService buildCodeGenerationRequestService() {
    final orchestrator = _codeGenerationOrchestrator;
    if (orchestrator == null) {
      throw StateError(
        'Code Generation Orchestrator ProductionCompositionRoot\'a verilmedi.',
      );
    }

    build();
    final module = _codeGenerationRuntimeModule!;
    return CodeGenerationRequestService(runtimeModule: module);
  }
  /// Creates the application facade for video and general content generation.
  ContentRequestService buildContentRequestService() {
    final orchestrator = _contentGenerationOrchestrator;
    if (orchestrator == null) {
      throw StateError('Content Generation Orchestrator ProductionCompositionRoot\'a verilmedi.');
    }
    build();
    return ContentRequestService(_contentGenerationRuntimeModule!);
  }

}
