import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/ares_app.dart';
import 'application/archive/archive_recorder.dart';
import 'application/codegen/code_generation_orchestrator.dart';
import 'application/codegen/code_generation_request_service.dart';
import 'application/codegen/code_validator_service.dart';
import 'application/codegen/code_writer_service.dart';
import 'application/codegen/project_scaffold_service.dart';
import 'application/codegen/prompt_builder_service.dart';
import 'application/content/content_generation_orchestrator.dart';
import 'application/content/content_request_service.dart';
import 'application/runtime/production/production_composition_root.dart';
import 'application/live_operations/live_operations_store.dart';
import 'application/settings/ares_settings.dart';
import 'core/security/cost_policy.dart';
import 'infrastructure/archive/file_work_archive_repository.dart';
import 'infrastructure/codegen/dynamic_ares_ai_gateway.dart';
import 'infrastructure/codegen/file_system_writer.dart';
import 'infrastructure/codegen/llm_code_generator.dart';
import 'infrastructure/environment/environment_health_service_impl.dart';
import 'infrastructure/storage/json_file_store.dart';
import 'infrastructure/video/ffmpeg_command_runner.dart';
import 'presentation/chat/chat_screen.dart';
import 'presentation/learning/learning_screen.dart';
import 'presentation/live_operations/live_operations_screen.dart';
import 'presentation/settings/ares_settings_screen.dart';
import 'presentation/voice/voice_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Derleme sırasında verilen ayarlar yalnızca ilk açılıştaki varsayılandır;
  // Ayarlar ekranında kaydedilenler her zaman önceliklidir.
  const defaults = AresSettings(
    localEnabled: bool.fromEnvironment('ARES_LOCAL_AI_ENABLED'),
    localBaseUrl: String.fromEnvironment('ARES_LOCAL_AI_BASE_URL', defaultValue: 'http://127.0.0.1:11434'),
    localModel: String.fromEnvironment('ARES_LOCAL_AI_MODEL', defaultValue: 'qwen2.5-coder:1.5b'),
    freeBaseUrl: String.fromEnvironment('ARES_FREE_AI_BASE_URL'),
    freeModel: String.fromEnvironment('ARES_FREE_AI_MODEL'),
  );

  final jsonStore = JsonFileStore();
  final settingsStore = AresSettingsStore(store: jsonStore, defaults: defaults);
  await settingsStore.load();

  final gateway = DynamicAresAiGateway(settings: settingsStore);
  final archive = FileWorkArchiveRepository(jsonStore);
  final recorder = ArchiveRecorder(archive);

  final codeOrchestrator = CodeGenerationOrchestrator(
    scaffoldService: const ProjectScaffoldService(),
    promptBuilder: const PromptBuilderService(),
    llmCodeGenerator: ApiLlmCodeGenerator(gateway: gateway),
    codeWriter: CodeWriterService(writer: FileSystemWriter()),
    validator: const CodeValidatorService(),
    aiCostClass: AiCostClass.local,
  );

  DefaultEnvironmentHealthService buildHealth() {
    final s = settingsStore.current;
    return DefaultEnvironmentHealthService(
      localBaseUrl: s.localEnabled ? s.localBaseUrl : '',
      localModel: s.localModel,
      freeBaseUrl: s.freeBaseUrl.trim().isEmpty ? null : s.freeBaseUrl,
      freeModel: s.freeModel,
      freeApiKey: s.freeApiKey.trim().isEmpty ? null : s.freeApiKey,
    );
  }

  final ffmpegRunner = const FfmpegCommandRunner();
  final contentOrchestrator = ContentGenerationOrchestrator(
    gateway: gateway,
    writer: CodeWriterService(writer: FileSystemWriter()),
    costClass: AiCostClass.local,
  );

  final compositionRoot = ProductionCompositionRoot(
    codeGenerationOrchestrator: codeOrchestrator,
    contentGenerationOrchestrator: contentOrchestrator,
  );
  final CodeGenerationRequestService codeService = compositionRoot.buildCodeGenerationRequestService();
  final ContentRequestService contentService = compositionRoot.buildContentRequestService();
  final liveOperationsStore = LiveOperationsStore();

  Future<GenerationResult> runCodeGeneration(
    String request, {
    void Function(String status)? onProgress,
  }) async {
    final id = 'mobil-${DateTime.now().microsecondsSinceEpoch}';
    liveOperationsStore.start(id: id, title: 'Mobil uygulama üretimi');
    void progress(String status) {
      liveOperationsStore.progress(id: id, message: status);
      onProgress?.call(status);
    }
    try {
      final result = await codeService.generate(request, onProgress: progress);
      if (result.success) {
        liveOperationsStore.complete(id: id, message: 'Mobil uygulama üretimi tamamlandı.');
      } else {
        liveOperationsStore.fail(id: id, message: result.errors.isEmpty ? 'Mobil uygulama üretimi başarısız.' : result.errors.first);
      }
      return result;
    } catch (error) {
      liveOperationsStore.fail(id: id, message: 'Mobil uygulama üretimi hata verdi.');
      rethrow;
    }
  }

  Future<ContentGenerationResult> runContentGeneration({
    required ContentMode mode,
    required String request,
    String duration = '60 saniye',
    String style = 'modern, temiz ve ARES uyumlu',
    String platform = 'YouTube Shorts',
    String contentType = 'uygulama fikri dokümanı',
    void Function(String status)? onProgress,
  }) async {
    final id = 'icerik-${DateTime.now().microsecondsSinceEpoch}';
    final title = mode == ContentMode.video ? 'Video üretimi' : 'Genel içerik üretimi';
    liveOperationsStore.start(id: id, title: title);
    void progress(String status) {
      liveOperationsStore.progress(id: id, message: status);
      onProgress?.call(status);
    }
    try {
      final result = await contentService.generate(
        mode: mode,
        request: request,
        duration: duration,
        style: style,
        platform: platform,
        contentType: contentType,
        onProgress: progress,
      );
      if (result.success) {
        liveOperationsStore.complete(id: id, message: '$title tamamlandı.');
      } else {
        liveOperationsStore.fail(id: id, message: result.errors.isEmpty ? '$title başarısız.' : result.errors.first);
      }
      await recorder.recordContent(
        modeLabel: mode.label,
        request: request,
        success: result.success,
        artifactCount: result.artifacts.length,
        errors: result.errors,
      );
      return result;
    } catch (error) {
      liveOperationsStore.fail(id: id, message: '$title hata verdi.');
      rethrow;
    }
  }

  runApp(
    AresApp(
      chatBuilder: (context) => AresChatScreen(
        gateway: gateway,
        archive: archive,
        onOpenSettings: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => AresSettingsScreen(store: settingsStore, gateway: gateway)),
        ),
        onOpenMobileProduction: (request, {onProgress}) => runCodeGeneration(request, onProgress: onProgress),
      ),
      settingsBuilder: (context) => AresSettingsScreen(store: settingsStore, gateway: gateway),
      voiceBuilder: (context) => VoiceScreen(
        onOpenChat: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => AresChatScreen(
          gateway: gateway,
          archive: archive,
          onOpenSettings: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => AresSettingsScreen(store: settingsStore, gateway: gateway))),
          onOpenMobileProduction: (request, {onProgress}) => runCodeGeneration(request, onProgress: onProgress),
        ))),
        onOpenSettings: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => AresSettingsScreen(store: settingsStore, gateway: gateway))),
        onOpenLiveOperations: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => LiveOperationsScreen(store: liveOperationsStore))),
        onMobileProduction: (request) => runCodeGeneration(request),
      ),
      learningBuilder: (context) => LearningScreen(archive: archive),
      healthServiceFactory: buildHealth,
      liveOperationsStore: liveOperationsStore,
      environmentHealthService: buildHealth(),
      onCodeGenerate: (request, {onProgress}) async {
        final result = await runCodeGeneration(request, onProgress: onProgress);
        await recorder.recordCodeGeneration(request: request, result: result);
        return result;
      },
      onVideoRender: ({required arguments, required relativeOutputRoot}) async {
        final safeRelative = relativeOutputRoot.replaceAll('\\', '/');
        if (safeRelative.startsWith('/') || safeRelative.contains('../') || safeRelative.contains('..\\')) {
          return const VideoRenderResult(success: false, message: 'Güvenli olmayan render çıktı yolu reddedildi.', outputFile: null);
        }
        final documents = await getApplicationDocumentsDirectory();
        final output = Directory('${documents.path}/$safeRelative');
        return ffmpegRunner.run(arguments: arguments, outputRoot: output, explicitUserApproval: true);
      },
      onContentGenerate: runContentGeneration,
    ),
  );
}
