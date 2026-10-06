# DEST-OS ARES — FINAL SOURCE SNAPSHOT

Bu dosya son turda değiştirilen/eklenen dosyaların tam içeriklerini taşır.


## `lib/main.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'app/ares_app.dart';
import 'application/codegen/code_generation_orchestrator.dart';
import 'application/codegen/code_generation_request_service.dart';
import 'application/environment/environment_health_service.dart';
import 'application/codegen/code_validator_service.dart';
import 'application/codegen/code_writer_service.dart';
import 'application/codegen/project_scaffold_service.dart';
import 'application/codegen/prompt_builder_service.dart';
import 'application/content/content_generation_orchestrator.dart';
import 'application/content/content_request_service.dart';
import 'application/runtime/production/production_composition_root.dart';
import 'core/security/cost_policy.dart';
import 'infrastructure/codegen/fallback_ares_ai_gateway.dart';
import 'infrastructure/codegen/fallback_llm_code_generator.dart';
import 'infrastructure/codegen/file_system_writer.dart';
import 'infrastructure/codegen/free_remote_ai_gateway_adapter.dart';
import 'infrastructure/codegen/llm_code_generator.dart';
import 'infrastructure/codegen/local_ai_gateway_adapter.dart';
import 'infrastructure/environment/environment_health_service_impl.dart';
import 'infrastructure/video/ffmpeg_command_runner.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const localBaseUrl = String.fromEnvironment('ARES_LOCAL_AI_BASE_URL', defaultValue: 'http://localhost:11434');
  const localModel = String.fromEnvironment('ARES_LOCAL_AI_MODEL', defaultValue: 'qwen3:4b');
  const freeBaseUrl = String.fromEnvironment('ARES_FREE_AI_BASE_URL');
  const freeModel = String.fromEnvironment('ARES_FREE_AI_MODEL', defaultValue: '');
  const freeApiKey = String.fromEnvironment('ARES_FREE_AI_API_KEY');
  const freeCostClassName = String.fromEnvironment('ARES_FREE_AI_COST_CLASS', defaultValue: 'free');
  final freeCostClass = freeCostClassName == 'limitedFree' ? AiCostClass.limitedFree : AiCostClass.free;

  final localGateway = LocalAiGatewayAdapter(baseUrl: localBaseUrl, model: localModel);
  final freeGateway = freeBaseUrl.trim().isEmpty
      ? null
      : FreeRemoteAiGatewayAdapter(
          baseUrl: freeBaseUrl,
          model: freeModel,
          apiKey: freeApiKey.trim().isEmpty ? null : freeApiKey,
        );

  final codeGenerator = FallbackLlmCodeGenerator(
    local: ApiLlmCodeGenerator(gateway: localGateway),
    free: freeGateway == null ? null : ApiLlmCodeGenerator(gateway: freeGateway),
    freeCostClass: freeCostClass,
  );

  final codeOrchestrator = CodeGenerationOrchestrator(
    scaffoldService: const ProjectScaffoldService(),
    promptBuilder: const PromptBuilderService(),
    llmCodeGenerator: codeGenerator,
    codeWriter: CodeWriterService(writer: FileSystemWriter()),
    validator: const CodeValidatorService(),
    aiCostClass: AiCostClass.local,
  );

  final environmentHealthService = DefaultEnvironmentHealthService(
    localBaseUrl: localBaseUrl,
    localModel: localModel,
    freeBaseUrl: freeBaseUrl.trim().isEmpty ? null : freeBaseUrl,
    freeModel: freeModel,
    freeApiKey: freeApiKey.trim().isEmpty ? null : freeApiKey,
  );

  final ffmpegRunner = const FfmpegCommandRunner();
  final contentGateway = FallbackAresAiGateway(local: localGateway, free: freeGateway);
  final contentOrchestrator = ContentGenerationOrchestrator(
    gateway: contentGateway,
    writer: CodeWriterService(writer: FileSystemWriter()),
    costClass: AiCostClass.local,
  );

  final compositionRoot = ProductionCompositionRoot(
    codeGenerationOrchestrator: codeOrchestrator,
    contentGenerationOrchestrator: contentOrchestrator,
  );
  final CodeGenerationRequestService codeService = compositionRoot.buildCodeGenerationRequestService();
  final ContentRequestService contentService = compositionRoot.buildContentRequestService();

  runApp(
    AresApp(
      onCodeGenerate: (request, {onProgress}) => codeService.generate(request, onProgress: onProgress),
      environmentHealthService: environmentHealthService,
      onVideoRender: ({required arguments, required relativeOutputRoot}) async {
        final safeRelative = relativeOutputRoot.replaceAll('\\', '/');
        if (safeRelative.startsWith('/') || safeRelative.contains('../') || safeRelative.contains('..\\')) {
          return const VideoRenderResult(success: false, message: 'Güvenli olmayan render çıktı yolu reddedildi.', outputFile: null);
        }
        final documents = await getApplicationDocumentsDirectory();
        final output = Directory('${documents.path}/$safeRelative');
        return ffmpegRunner.run(arguments: arguments, outputRoot: output, explicitUserApproval: true);
      },
      onContentGenerate: ({required mode, required request, duration = '60 saniye', style = 'modern, temiz ve ARES uyumlu', platform = 'YouTube Shorts', contentType = 'uygulama fikri dokümanı', onProgress}) =>
          contentService.generate(mode: mode, request: request, duration: duration, style: style, platform: platform, contentType: contentType, onProgress: onProgress),
    ),
  );
}

```


## `lib/app/ares_app.dart`

```dart
import 'package:flutter/material.dart';

import '../domain/codegen/generation_result.dart';
import '../domain/content/content_generation_result.dart';
import '../domain/content/content_mode.dart';
import '../application/environment/environment_health_service.dart';
import '../infrastructure/video/ffmpeg_command_runner.dart';
import '../presentation/home/ares_home_screen.dart';

/// Root Flutter application for DEST-OS ARES.
class AresApp extends StatelessWidget {
  /// Creates the application.
  const AresApp({super.key, this.onCodeGenerate, this.onContentGenerate, this.environmentHealthService, this.onVideoRender});

  /// Application-layer mobile generation facade.
  final Future<GenerationResult> Function(String request, {void Function(String status)? onProgress})? onCodeGenerate;

  /// Explicitly approved video render facade.
  final Future<VideoRenderResult> Function({required List<String> arguments, required String relativeOutputRoot})? onVideoRender;

  /// Application-layer content generation facade.
  /// Optional dependency health facade.
  final EnvironmentHealthService? environmentHealthService;

  final Future<ContentGenerationResult> Function({
    required ContentMode mode,
    required String request,
    String duration,
    String style,
    String platform,
    String contentType,
    void Function(String status)? onProgress,
  })? onContentGenerate;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DEST-OS ARES',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true, colorSchemeSeed: Colors.cyan),
        home: AresHomeScreen(onCodeGenerate: onCodeGenerate, onContentGenerate: onContentGenerate, environmentHealthService: environmentHealthService, onVideoRender: onVideoRender),
      );
}

```


## `lib/presentation/home/ares_home_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../../core/constants/ares_constants.dart';
import '../../domain/codegen/generation_result.dart';
import '../../domain/content/content_generation_result.dart';
import '../../application/environment/environment_health_service.dart';
import '../../infrastructure/video/ffmpeg_command_runner.dart';
import '../../domain/content/content_mode.dart';
import '../codegen/code_generation_screen.dart';
import '../content/content_generation_screen.dart';

/// ARES tablet ana ekranı ve üç üretim modunun giriş noktasıdır.
class AresHomeScreen extends StatefulWidget {
  /// Creates the ARES home screen.
  const AresHomeScreen({
    super.key,
    this.onCodeGenerate,
    this.onContentGenerate,
    this.environmentHealthService,
    this.onVideoRender,
  });

  /// Application-layer mobile-app generation facade.
  final Future<GenerationResult> Function(
    String request, {
    void Function(String status)? onProgress,
  })? onCodeGenerate;

  /// Application-layer video/general-content facade.
  final Future<ContentGenerationResult> Function({
    required ContentMode mode,
    required String request,
    String duration,
    String style,
    String platform,
    String contentType,
    void Function(String status)? onProgress,
  })? onContentGenerate;

  /// Dependency health service used for the tablet status card.
  final EnvironmentHealthService? environmentHealthService;

  /// Explicit video render facade requiring a user action.
  final Future<VideoRenderResult> Function({required List<String> arguments, required String relativeOutputRoot})? onVideoRender;


  @override
  State<AresHomeScreen> createState() => _AresHomeScreenState();
}

class _AresHomeScreenState extends State<AresHomeScreen> {
  EnvironmentHealth? _health;
  @override
  void initState() {
    super.initState();
    final service = widget.environmentHealthService;
    if (service != null) {
      service.check().then((value) { if (mounted) setState(() => _health = value); });
    }
  }

  void _openMobile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CodeGenerationScreen(onGenerate: widget.onCodeGenerate),
    ));
  }

  void _openContent(BuildContext context, ContentMode mode) {
    final callback = widget.onContentGenerate;
    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçerik üretim servisi yapılandırılmamış.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ContentGenerationScreen(mode: mode, onGenerate: callback, onRender: widget.onVideoRender),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              children: [
                const Text(
                  AresConstants.applicationName,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'İbrahim Halil Ezen • Kişisel Üretim Merkezi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 18),
                if (_health != null) _HealthCard(health: _health!),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cardWidth = width >= 900 ? (width - 32) / 3 : width;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _ModeCard(
                        width: cardWidth,
                        icon: Icons.phone_android_rounded,
                        title: 'Mobil Uygulama Üret',
                        description: 'Fikirden Flutter proje iskeletine kadar kod üret.',
                        onTap: () => _openMobile(context),
                      ),
                      _ModeCard(
                        width: cardWidth,
                        icon: Icons.movie_creation_outlined,
                        title: 'Video İçerik Üret',
                        description: 'Senaryo, shot list, altyazı ve üretim paketini hazırla.',
                        onTap: () => _openContent(context, ContentMode.video),
                      ),
                      _ModeCard(
                        width: cardWidth,
                        icon: Icons.description_outlined,
                        title: 'Genel İçerik Üret',
                        description: 'Doküman, pazarlama metni, post serisi veya ürün açıklaması üret.',
                        onTap: () => _openContent(context, ContentMode.general),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});
  final EnvironmentHealth health;
  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF08131C),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SİSTEM DURUMU', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(spacing: 24, runSpacing: 10, children: [
              _HealthItem(health.localAi),
              _HealthItem(health.freeAi),
              _HealthItem(health.ffmpeg),
            ]),
            if (!health.localAi.ready && !health.freeAi.ready) ...[
              const SizedBox(height: 14),
              const Text('AI kurulumu gerekiyor: Ollama/LM Studio + model kurun veya doğrulanmış ücretsiz endpoint yapılandırın. AI hazır değilse üretim başarılı gösterilmez.', style: TextStyle(color: Colors.orangeAccent, height: 1.3)),
            ],
          ]),
        ),
      );
}

class _HealthItem extends StatelessWidget {
  const _HealthItem(this.health);
  final DependencyHealth health;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(health.ready ? Icons.check_circle : Icons.error_outline, color: health.ready ? Colors.greenAccent : Colors.orangeAccent, size: 20),
        const SizedBox(width: 7),
        Text('${health.name}: ${health.message}', style: const TextStyle(color: Colors.white70)),
      ]);
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.width, required this.icon, required this.title, required this.description, required this.onTap});
  final double width;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          color: const Color(0xFF0A1722),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.cyanAccent.withOpacity(.22))),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: Colors.cyanAccent, size: 36),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.35)),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerRight, child: Icon(Icons.arrow_forward_rounded, color: Colors.cyanAccent)),
              ]),
            ),
          ),
        ),
      );
}

```


## `lib/presentation/content/content_generation_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import '../../domain/content/general_content_type.dart';
import '../../infrastructure/video/ffmpeg_command_runner.dart';

/// Video ve genel içerik üretimini kullanıcıya sunan tablet ekranıdır.
class ContentGenerationScreen extends StatefulWidget {
  /// Creates a content generation screen.
  const ContentGenerationScreen({super.key, required this.mode, required this.onGenerate, this.onRender});
  /// Selected content mode.
  final ContentMode mode;
  /// Application-layer generation facade.
  final Future<ContentGenerationResult> Function({
    required ContentMode mode,
    required String request,
    String duration,
    String style,
    String platform,
    String contentType,
    void Function(String status)? onProgress,
  }) onGenerate;
  /// Optional explicit video render action. The user must press the render button.
  final Future<VideoRenderResult> Function({required List<String> arguments, required String relativeOutputRoot})? onRender;
  @override
  State<ContentGenerationScreen> createState() => _ContentGenerationScreenState();
}

class _ContentGenerationScreenState extends State<ContentGenerationScreen> {
  final _request = TextEditingController();
  final _duration = TextEditingController(text: '60 saniye');
  final _style = TextEditingController(text: 'modern, temiz ve ARES uyumlu');
  final _platform = TextEditingController(text: 'YouTube Shorts');
  GeneralContentType _generalType = GeneralContentType.appIdea;
  bool _busy = false;
  String _status = 'Hazır';
  ContentGenerationResult? _result;
  String? _renderStatus;

  @override
  void dispose() { _request.dispose(); _duration.dispose(); _style.dispose(); _platform.dispose(); super.dispose(); }

  Future<void> _run() async {
    if (_request.text.trim().length < 8) { setState(() => _status = 'Daha açıklayıcı bir istek yazın.'); return; }
    setState(() { _busy = true; _result = null; _status = 'Başlatılıyor...'; });
    try {
      final result = await widget.onGenerate(
        mode: widget.mode,
        request: _request.text,
        duration: _duration.text,
        style: _style.text,
        platform: _platform.text,
        contentType: _generalType.label,
        onProgress: (value) { if (mounted) setState(() => _status = value); },
      );
      if (mounted) setState(() { _result = result; _busy = false; _status = result.success ? 'Tamamlandı' : 'Hata'; });
    } catch (error) {
      if (mounted) setState(() { _busy = false; _status = 'Hata: $error'; });
    }
  }

  Future<void> _render() async {
    final result = _result;
    final callback = widget.onRender;
    if (result == null || callback == null) return;
    final raw = result.metrics['renderArguments'];
    if (raw is! List) { setState(() => _renderStatus = 'Render planı bulunamadı.'); return; }
    setState(() => _renderStatus = 'Render başlatılıyor...');
    final relativeOutputRoot = result.metrics['outputRoot'] is String ? result.metrics['outputRoot'] as String : 'ARES_Output/video/uretim';
    final render = await callback(arguments: raw.whereType<String>().toList(growable: false), relativeOutputRoot: relativeOutputRoot);
    if (mounted) setState(() => _renderStatus = render.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(title: Text(widget.mode.label), backgroundColor: const Color(0xFF07131D)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            TextField(
              controller: _request,
              minLines: 6,
              maxLines: 10,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Yüksek seviye fikir / istek',
                hintText: 'Örneğin: 60 saniyelik verimlilik videosu üret',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.mode == ContentMode.video) ...[
              const SizedBox(height: 14),
              _Input(controller: _duration, label: 'Süre'),
              const SizedBox(height: 10),
              _Input(controller: _style, label: 'Stil'),
              const SizedBox(height: 10),
              _Input(controller: _platform, label: 'Platform'),
            ],
            if (widget.mode == ContentMode.general) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<GeneralContentType>(
                value: _generalType,
                decoration: const InputDecoration(labelText: 'İçerik türü', border: OutlineInputBorder()),
                items: GeneralContentType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                onChanged: _busy ? null : (value) { if (value != null) setState(() => _generalType = value); },
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(height: 54, child: FilledButton.icon(onPressed: _busy ? null : _run, icon: const Icon(Icons.auto_awesome), label: Text(_busy ? 'ÜRETİLİYOR...' : 'ÜRET')),
            const SizedBox(height: 18),
            _Panel('DURUM', Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 16))),
            if (_result != null) ...[
              const SizedBox(height: 18),
              _Panel('SONUÇ', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_result!.success ? 'Üretim başarılı.' : 'Üretim başarısız.', style: TextStyle(color: _result!.success ? Colors.cyanAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._result!.artifacts.map((a) => Text('• ${a.relativePath}', style: const TextStyle(color: Colors.white70))),
                ..._result!.errors.map((e) => Text('Hata: $e', style: const TextStyle(color: Colors.redAccent))),
                ..._result!.suggestedActions.map((e) => Text('Öneri: $e', style: const TextStyle(color: Colors.amberAccent))),
                if (widget.mode == ContentMode.video && _result!.success && widget.onRender != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _render,
                      icon: const Icon(Icons.movie_filter_outlined),
                      label: const Text('RENDER’I BAŞLAT'),
                    ),
                  ),
                  if (_renderStatus != null) ...[
                    const SizedBox(height: 10),
                    Text(_renderStatus!, style: const TextStyle(color: Colors.white70)),
                  ],
                ],
              ])),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      );
}

class _Panel extends StatelessWidget {
  const _Panel(this.title, this.child);
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFF0A1722), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.cyanAccent.withOpacity(.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)), const SizedBox(height: 10), child]),
  );
}

```


## `lib/application/codegen/project_scaffold_service.dart`

```dart
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/codegen/project_spec.dart';

/// ProjectSpec kullanarak yeni bir Flutter projesinin temel Clean Architecture
/// iskeletini bellekte CodeArtifact listesi olarak üretir.
///
/// Bu servis hiçbir dosyaya yazmaz, klasör oluşturmaz ve dış sistemlere erişmez.
class ProjectScaffoldService {
  /// Creates an in-memory Flutter project scaffold service.
  const ProjectScaffoldService();

  static const String _generatorName = 'ProjectScaffoldService';

  /// Verilen [ProjectSpec] için temel proje dosyalarını üretir.
  ///
  /// Üretilen artifact'ler daha sonra ayrı bir writer katmanı tarafından
  /// diske yazılabilir. Bu servis kendi başına herhangi bir yazma işlemi yapmaz.
  List<CodeArtifact> generate(ProjectSpec spec) {
    final artifacts = <CodeArtifact>[
      _directoryMarker('lib/core/.gitkeep'),
      _directoryMarker('lib/domain/.gitkeep'),
      _directoryMarker('lib/application/.gitkeep'),
      _directoryMarker('lib/infrastructure/.gitkeep'),
      _directoryMarker('lib/presentation/.gitkeep'),
      _directoryMarker('test/.gitkeep'),
      _dartArtifact(
        'lib/main.dart',
        _mainDart(spec),
      ),
      _dartArtifact(
        'lib/app/app.dart',
        _appDart(spec),
      ),
      _yamlArtifact(
        'pubspec.yaml',
        _pubspec(spec),
      ),
      _yamlArtifact(
        'analysis_options.yaml',
        _analysisOptions(),
      ),
      CodeArtifact(
        relativePath: 'README.md',
        content: _readme(spec),
        type: ArtifactType.markdown,
        generatedBy: _generatorName,
      ),
      CodeArtifact(
        relativePath: 'BUILD_READY.md',
        content: _buildReady(),
        type: ArtifactType.markdown,
        generatedBy: _generatorName,
      ),
      CodeArtifact(
        relativePath: 'SMOKE_CHECKLIST.md',
        content: _smokeChecklist(),
        type: ArtifactType.markdown,
        generatedBy: _generatorName,
      ),
    ];

    return List.unmodifiable(artifacts);
  }

  CodeArtifact _dartArtifact(String path, String content) {
    return CodeArtifact(
      relativePath: path,
      content: content,
      type: ArtifactType.dart,
      generatedBy: _generatorName,
    );
  }

  CodeArtifact _yamlArtifact(String path, String content) {
    return CodeArtifact(
      relativePath: path,
      content: content,
      type: ArtifactType.yaml,
      generatedBy: _generatorName,
    );
  }

  CodeArtifact _directoryMarker(String path) {
    return CodeArtifact(
      relativePath: path,
      content: '',
      type: ArtifactType.other,
      generatedBy: _generatorName,
    );
  }

  String _mainDart(ProjectSpec spec) {
    final description = _dartComment(spec.description);
    return '''// $description
import 'app/app.dart';

void main() {
  runAresApp();
}
''';
  }

  String _appDart(ProjectSpec spec) {
    final appName = _escapeDartString(spec.projectName);
    return '''import 'package:flutter/material.dart';

/// $appName uygulamasının temel Flutter uygulama katmanıdır.
class AresApp extends StatelessWidget {
  const AresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appName',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('ARES'),
        ),
      ),
    );
  }
}

void runAresApp() {
  runApp(const AresApp());
}
''';
  }

  String _pubspec(ProjectSpec spec) {
    final packages = _uniqueSorted(spec.requiredPackages);
    final dependencyLines = <String>[];
    for (final packageName in packages) {
      dependencyLines.add('  ${_yamlKey(packageName)}: any');
    }

    final dependencies = dependencyLines.isEmpty
        ? 'dependencies:\n  flutter:\n    sdk: flutter'
        : 'dependencies:\n  flutter:\n    sdk: flutter\n${dependencyLines.join('\n')}';

    return '''name: ${_yamlKey(spec.packageName)}
description: ${_yamlString(spec.description)}
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.5.0 <4.0.0"

$dependencies

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: any

flutter:
  uses-material-design: true
''';
  }

  String _readme(ProjectSpec spec) {
    return '''# ${spec.projectName}

${spec.description}

## Mimari

Clean Architecture: domain / application / infrastructure / presentation.

## Build

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
''';
  }

  String _buildReady() {
    return '''# BUILD READY

Bu proje Flutter build hazırlık kontrolünden geçtikten sonra oluşturulmuştur.

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Bu komutların gerçekten çalıştırılması Flutter SDK bulunan hedef ortamda yapılmalıdır.
''';
  }

  String _smokeChecklist() {
    return '''# SMOKE CHECKLIST

- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --release`
- [ ] APK cihazda açıldı
''';
  }

  String _analysisOptions() {
    return '''include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
''';
  }

  List<String> _uniqueSorted(List<String> values) {
    final normalized = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed != 'flutter') {
        normalized.add(trimmed);
      }
    }
    final result = normalized.toList()..sort();
    return result;
  }

  String _yamlKey(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return trimmed;
    }
    return _yamlString(trimmed);
  }

  String _yamlString(String value) {
    final escaped = value.replaceAll('"', '\\"');
    return '"$escaped"';
  }

  String _escapeDartString(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  String _dartComment(String value) {
    return value
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('*/', '* /')
        .trim();
  }
}

```


## `lib/application/codegen/build_readiness_service.dart`

```dart
import '../../domain/codegen/code_artifact.dart';

/// Reports whether generated artifacts meet the minimum Flutter build contract.
class BuildReadinessReport {
  /// Creates an immutable build-readiness report.
  const BuildReadinessReport({
    required this.ready,
    required this.hasMain,
    required this.hasPubspec,
    required this.hasScreen,
    required this.hasAnalysisOptions,
    required this.hasDomain,
    required this.hasApplication,
    required this.brokenCriticalImports,
    required this.checks,
    required this.commands,
  });

  /// Whether all required checks passed.
  final bool ready;

  /// Whether lib/main.dart exists.
  final bool hasMain;

  /// Whether pubspec.yaml exists.
  final bool hasPubspec;

  /// Whether at least one presentation Dart file exists.
  final bool hasScreen;

  /// Whether analysis_options.yaml exists.
  final bool hasAnalysisOptions;

  /// Whether at least one domain Dart file exists.
  final bool hasDomain;

  /// Whether at least one application Dart file exists.
  final bool hasApplication;

  /// Critical import paths that could not be resolved.
  final List<String> brokenCriticalImports;

  /// Human-readable check results.
  final List<String> checks;

  /// Commands a user can run when Flutter is available.
  final List<String> commands;

  /// Converts the report to Markdown suitable for generated documentation.
  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# ARES Build Readiness')
      ..writeln()
      ..writeln('Durum: **${ready ? 'HAZIR' : 'HAZIR DEĞİL'}**')
      ..writeln()
      ..writeln('## Kontroller');
    for (final check in checks) {
      buffer.writeln('- $check');
    }
    if (brokenCriticalImports.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Kırık kritik importlar');
      for (final item in brokenCriticalImports) {
        buffer.writeln('- `$item`');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Flutter komutları')
      ..writeln('```text');
    for (final command in commands) {
      buffer.writeln(command);
    }
    buffer.writeln('```');
    return buffer.toString();
  }
}

/// Performs deterministic build-readiness checks without invoking Flutter.
class BuildReadinessService {
  /// Creates the readiness service.
  const BuildReadinessService();

  /// Checks the generated artifact collection.
  BuildReadinessReport evaluate(List<CodeArtifact> artifacts) {
    final paths = artifacts.map((artifact) => artifact.relativePath).toSet();
    final hasMain = paths.contains('lib/main.dart');
    final hasPubspec = paths.contains('pubspec.yaml');
    final hasAnalysis = paths.contains('analysis_options.yaml');
    final hasDomain = artifacts.any((artifact) => artifact.relativePath.startsWith('lib/domain/') && artifact.relativePath.endsWith('.dart'));
    final hasApplication = artifacts.any((artifact) => artifact.relativePath.startsWith('lib/application/') && artifact.relativePath.endsWith('.dart'));
    final hasReadme = paths.contains('README.md');
    final hasBuildReady = paths.contains('BUILD_READY.md');
    final hasSmokeChecklist = paths.contains('SMOKE_CHECKLIST.md');
    final hasScreen = artifacts.any(
      (artifact) =>
          artifact.relativePath.startsWith('lib/presentation/') &&
          artifact.relativePath.endsWith('.dart'),
    );

    final brokenImports = <String>[];
    final dartPaths = paths.where((path) => path.endsWith('.dart')).toSet();
    final importPattern = RegExp(r"import\s+['\"](lib/[^'\"]+)['\"];");
    for (final artifact in artifacts.where((item) => item.type.name == 'dart')) {
      for (final match in importPattern.allMatches(artifact.content)) {
        final imported = match.group(1);
        if (imported != null && !dartPaths.contains(imported)) {
          brokenImports.add('${artifact.relativePath} -> $imported');
        }
      }
    }

    final checks = <String>[
      '${hasMain ? '✓' : '✗'} lib/main.dart',
      '${hasPubspec ? '✓' : '✗'} pubspec.yaml',
      '${hasAnalysis ? '✓' : '✗'} analysis_options.yaml',
      '${hasDomain ? '✓' : '✗'} en az bir domain dosyası',
      '${hasApplication ? '✓' : '✗'} en az bir application dosyası',
      '${hasScreen ? '✓' : '✗'} en az bir presentation ekranı',
      '${hasReadme ? '✓' : '✗'} README.md',
      '${hasBuildReady ? '✓' : '✗'} BUILD_READY.md',
      '${hasSmokeChecklist ? '✓' : '✗'} SMOKE_CHECKLIST.md',
      '${brokenImports.isEmpty ? '✓' : '✗'} kritik relative importlar',
    ];

    final ready = hasMain && hasPubspec && hasAnalysis && hasReadme && hasDomain && hasApplication && hasScreen && hasBuildReady && hasSmokeChecklist && brokenImports.isEmpty;
    return BuildReadinessReport(
      ready: ready,
      hasMain: hasMain,
      hasPubspec: hasPubspec,
      hasScreen: hasScreen,
      hasAnalysisOptions: hasAnalysis,
      hasDomain: hasDomain,
      hasApplication: hasApplication,
      brokenCriticalImports: List.unmodifiable(brokenImports),
      checks: List.unmodifiable(checks),
      commands: const <String>[
        'flutter pub get',
        'flutter analyze',
        'flutter test',
        'flutter build apk --release',
      ],
    );
  }
}

```


## `lib/application/codegen/README.md`

```markdown
# DEST-OS ARES Kod Üretim Motoru

## Tablet ilk kurulum

1. Flutter SDK bulunan geliştirme ortamında ARES'i build edin.
2. Yerel AI için Ollama veya LM Studio kurun.
3. Örnek Ollama modeli: `qwen3:4b`.
4. ARES'i şu değerlerle başlatabilirsiniz:

```text
--dart-define=ARES_LOCAL_AI_BASE_URL=http://localhost:11434
--dart-define=ARES_LOCAL_AI_MODEL=qwen3:4b
```

LM Studio OpenAI uyumlu endpoint kullanıyorsa base URL ve model adını ona göre verin.

## Ücretsiz uzak AI

Yerel AI erişilemiyorsa doğrulanmış ücretsiz/limited-free OpenAI-compatible endpoint yapılandırılabilir:

```text
--dart-define=ARES_FREE_AI_BASE_URL=https://...
--dart-define=ARES_FREE_AI_MODEL=...
--dart-define=ARES_FREE_AI_API_KEY=...
--dart-define=ARES_FREE_AI_COST_CLASS=free
```

API anahtarı kaynak koda yazılmaz. Gerçek dağıtımda secure storage veya güvenli CI/secret yönetimi tercih edilmelidir.

## İlk üretim

Ana ekran → **Mobil Uygulama Üret** → `Basit bir Counter uygulaması üret` → ÜRET.

Sıra: ProjectSpec → Scaffold → Product Manager → Architect → Flutter Developer → QA → DevOps → Validator/Self-Healing → Build Readiness → Secure Writer.

Çıktı ARES'in kaynak `lib/` ağacına değil, uygulama belgeleri altında `ARES_Generated_Projects/<proje>/` köküne yazılır.

## Video

Ana ekran → **Video İçerik Üret**. Paket içinde `video_brief.md`, `script.md`, `shot_list.md`, `voiceover_script.md`, `captions.srt`, `thumbnail_prompt.md`, `assets_plan.md`, `timeline.json`, `render_plan.json`, `production_checklist.md` ve kalite çıktıları bulunur.

Gerçek video render paket üretiminden farklıdır. ARES otomatik olarak ffmpeg çalıştırmaz. Kullanıcı **RENDER'I BAŞLAT** düğmesine basarsa, yalnızca allowlist edilmiş ffmpeg argümanları `runInShell:false`, timeout ve ayrı `ARES_Output/video/<slug>/` çalışma kökü ile çalıştırılır. ffmpeg yoksa veya medya girdisi yoksa gerçek render yapılmış gibi gösterilmez.

## Genel içerik

Genel içerik modu standart dosya sözleşmelerine göre doküman, pazarlama metni, post serisi veya ürün açıklaması üretir.

## Güvenlik

- Paid ve unknown AI otomatik çalışmaz.
- Mock yalnızca test içindir.
- Path traversal engellenir.
- Üretilen çıktı ARES kaynak ağacını ezmez.
- Dış komutlar kullanıcı onayı olmadan çalıştırılmaz.
- Komutlar shell üzerinden çalıştırılmaz.
- Kullanıcıya ait gizli veri loglara yazılmaz.

## ffmpeg kurulumu

Render isteğe bağlıdır. ffmpeg kurulmadıysa ARES video paketini yine üretir ve `render_plan.json` dosyasını hazırlar; render tamamlandı mesajı göstermez.

- Windows: ffmpeg'i güvenilir bir dağıtımdan kurup PATH'e ekleyin.
- Linux: dağıtımınızın paket yöneticisiyle ffmpeg kurun.
- Android tablette: sistem PATH'inde ffmpeg bulunması garanti değildir; ARES bu durumda yalnızca güvenli render planını sunar.

Render komutları ARES tarafından oluşturulur, shell üzerinden çalıştırılmaz, allowlist uygulanır ve çalışma dizini yalnızca video output köküyle sınırlıdır.

```


## `lib/application/content/content_generation_orchestrator.dart`

```dart
import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../application/runtime/paid_ai_runtime_gate.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/content/content_generation_result.dart';
import '../../domain/content/content_mode.dart';
import '../../domain/runtime/ai_runtime_request.dart';
import '../codegen/code_validator_service.dart';
import '../codegen/code_writer_service.dart';
import '../video/ffmpeg_command_builder.dart';

/// Video ve genel içerik üretimini ortak güvenlik ve kalite kapısından geçirir.
class ContentGenerationOrchestrator {
  /// Creates a content orchestrator with an ARES AI gateway and secure writer.
  const ContentGenerationOrchestrator({
    required AresAiGateway gateway,
    required CodeWriterService writer,
    CodeValidatorService validator = const CodeValidatorService(),
    PaidAiRuntimeGate paidGate = const PaidAiRuntimeGate(),
    this.costClass = AiCostClass.local,
    this.outputPrefix = 'ARES_Output',
  })  : _gateway = gateway,
        _writer = writer,
        _validator = validator,
        _paidGate = paidGate;

  final AresAiGateway _gateway;
  final CodeWriterService _writer;
  final CodeValidatorService _validator;
  final PaidAiRuntimeGate _paidGate;

  /// AI maliyet sınıfı.
  final AiCostClass costClass;

  /// Separate output root under the application documents directory.
  final String outputPrefix;

  /// Generates a video or general-content package from a high-level request.
  Future<ContentGenerationResult> generate({
    required ContentMode mode,
    required String request,
    String duration = '60 saniye',
    String style = 'modern, temiz ve ARES uyumlu',
    String platform = 'YouTube Shorts',
    String contentType = 'uygulama fikri dokümanı',
    void Function(String status)? onProgress,
  }) async {
    final text = request.trim();
    if (text.length < 8) {
      return const ContentGenerationResult(
        success: false,
        artifacts: <CodeArtifact>[],
        errors: <String>['İstek çok kısa. Üretilecek içeriğin amacını açıkça yazın.'],
        suggestedActions: <String>['En az birkaç kelimelik somut bir fikir girin.'],
        metrics: <String, Object?>{},
      );
    }
    onProgress?.call('İstek: içerik üretim talebi hazırlanıyor.');
    final instruction = _buildInstruction(mode, text, duration, style, platform, contentType);
    final gate = _paidGate.evaluate(AiRuntimeRequest(
      instruction: instruction,
      costClass: costClass,
      metadata: <String, Object?>{'feature': 'content_generation', 'mode': mode.name},
    ));
    if (!gate.mayRun) {
      return ContentGenerationResult(
        success: false,
        artifacts: const <CodeArtifact>[],
        errors: <String>[gate.reason],
        suggestedActions: const <String>[
          'Yerel AI veya doğrulanmış ücretsiz AI yapılandırın.',
          'Ücretli AI kullanacaksanız açık kullanıcı onayı gereklidir.',
        ],
        metrics: <String, Object?>{'costClass': costClass.name},
      );
    }
    onProgress?.call('Product Manager: fikir ve kabul kriterleri netleştiriliyor.');
    final pm = await _agentCall('ProductManager', '''İstek: $text\nMod: ${mode.name}\nSüre: $duration\nStil: $style\nPlatform: $platform\nİçerik türü: $contentType\nSadece brief.md artifact'i üret ve kabul kriterlerini yaz.''');
    if (pm is AresFailure<List<CodeArtifact>>) return _failure(pm.message);

    onProgress?.call('Architect: içerik üretim planı hazırlanıyor.');
    final architect = await _agentCall('Architect', '''İstek: $text\nMod: ${mode.name}\nİçerik türü: $contentType\nProduct Manager çıktısı: ${_artifactText((pm as AresSuccess<List<CodeArtifact>>).value)}\nSadece architecture.md artifact'i üret; üretim adımlarını ve dosya sözleşmesini tanımla.''');
    if (architect is AresFailure<List<CodeArtifact>>) return _failure(architect.message);

    onProgress?.call('Specialist Producer: içerik paketi üretiliyor.');
    final specialist = await _agentCall('SpecialistProducer', _buildInstruction(mode, text, duration, style, platform, contentType) + '\nProduct Manager: ${_artifactText((pm as AresSuccess<List<CodeArtifact>>).value)}\nArchitect: ${_artifactText((architect as AresSuccess<List<CodeArtifact>>).value)}');
    if (specialist is AresFailure<List<CodeArtifact>>) return _failure(specialist.message);
    final specialistArtifacts = (specialist as AresSuccess<List<CodeArtifact>>).value;

    onProgress?.call('QA Engineer: çıktı sözleşmesi kontrol ediliyor.');
    final qa = await _agentCall('QAEngineer', '''İstek: $text\nMod: ${mode.name}\nÜretilen yollar: ${specialistArtifacts.map((a) => a.relativePath).join(', ')}\nKısa kalite kontrol raporu üret ve quality_checklist.md artifact'i döndür.''');
    if (qa is AresFailure<List<CodeArtifact>>) return _failure(qa.message);

    onProgress?.call('DevOps / Release: üretim ve yayın kontrolü hazırlanıyor.');
    final devops = await _agentCall('DevOps', '''İstek: $text\nMod: ${mode.name}\nPlatform: $platform\nÜretilen yollar: ${specialistArtifacts.map((a) => a.relativePath).join(', ')}\nGüvenli üretim/yayın kontrolü hazırla. Video ise production_checklist.md; diğer içerikte release_checklist.md üret.''');
    if (devops is AresFailure<List<CodeArtifact>>) return _failure(devops.message);

    final artifacts = <CodeArtifact>[
      ...((pm as AresSuccess<List<CodeArtifact>>).value),
      ...((architect as AresSuccess<List<CodeArtifact>>).value),
      ...specialistArtifacts,
      ...((qa as AresSuccess<List<CodeArtifact>>).value),
      ...((devops as AresSuccess<List<CodeArtifact>>).value),
    ];

    if (mode == ContentMode.video) {
      _appendVideoPipelineArtifacts(artifacts, duration: duration, platform: platform);
    }

    final contractErrors = _contractErrors(mode, contentType, artifacts);
    if (contractErrors.isNotEmpty) {
      return ContentGenerationResult(
        success: false, artifacts: artifacts, errors: contractErrors,
        suggestedActions: const <String>['Ajanlardan biri zorunlu dosya sözleşmesini tamamlamadı; üretimi tekrar deneyin.'],
        metrics: <String, Object?>{'costClass': costClass.name},
      );
    }

    final validation = _validator.validate(artifacts);
    if (!validation.isValid) {
      return ContentGenerationResult(
        success: false,
        artifacts: artifacts,
        errors: validation.errors,
        suggestedActions: validation.suggestedActions,
        metrics: <String, Object?>{},
      );
    }
    onProgress?.call('Yazma: içerik paketi güvenli çıktı köküne yazılıyor.');
    final requestSafe = _safeRequestFolder(text);
    final writeArtifacts = artifacts.map((artifact) => artifact.copyWith(relativePath: '$outputPrefix/${mode.name}/$requestSafe/${artifact.relativePath}')).toList(growable: false);
    final writeResult = await _writer.writeArtifacts(writeArtifacts, overwrite: false);
    if (!writeResult.success) {
      return ContentGenerationResult(
        success: false,
        artifacts: artifacts,
        errors: writeResult.errors,
        suggestedActions: const <String>['Çıktı klasörünün yazılabilir olduğunu kontrol edin.'],
        metrics: <String, Object?>{'written': writeResult.writtenPaths.length},
      );
    }
    onProgress?.call('Tamam: içerik paketi hazır.');
    return ContentGenerationResult(
      success: true,
      artifacts: artifacts,
      errors: const <String>[],
      suggestedActions: const <String>[],
      metrics: <String, Object?>{
        'written': writeResult.writtenPaths.length,
        'costClass': costClass.name,
        'outputRoot': '$outputPrefix/${mode.name}/$requestSafe',
        if (mode == ContentMode.video) 'renderArguments': const FfmpegCommandBuilder().buildMp4Command(outputFileName: 'render.mp4', durationSeconds: _parseDurationSeconds(duration), videoInput: 'assets/video_source.mp4'),
      },
    );
  }

  String _safeRequestFolder(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'uretim' : normalized.substring(0, normalized.length > 60 ? 60 : normalized.length);
  }

  Future<AresResult<List<CodeArtifact>>> _agentCall(String role, String instruction) async {
    final result = await _gateway.generate(AiRequest(instruction: '''Sen DEST-OS ARES $role ajanısın. Çıktı yalnızca geçerli JSON olsun: {"artifacts":[{"relativePath":"...","content":"...","type":"markdown|other","generatedBy":"$role"}]}. Path göreli olmalı ve ARES kaynak kodunu değiştirmemeli.\n$instruction''', costClass: costClass));
    if (result is AresFailure<AiResponse>) return AresFailure<List<CodeArtifact>>(result.message);
    try {
      return _parseArtifacts((result as AresSuccess<AiResponse>).value.text);
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('Ajan $role çıktısı çözülemedi: $error');
    }
  }

  ContentGenerationResult _failure(String message) => ContentGenerationResult(
        success: false, artifacts: const <CodeArtifact>[], errors: <String>[message],
        suggestedActions: const <String>['Local AI modelini, endpoint adresini ve JSON çıktı sözleşmesini kontrol edin.'],
        metrics: <String, Object?>{'costClass': costClass.name},
      );

  String _artifactText(List<CodeArtifact> artifacts) => artifacts.map((a) => '${a.relativePath}:\n${a.content}').join('\n');

  String _buildInstruction(ContentMode mode, String request, String duration, String style, String platform, String contentType) {
    final required = _specialistPaths(mode, contentType);
    final contract = mode == ContentMode.video
        ? 'Specialist Producer zorunlu yolları: ${required.join(', ')}. DevOps production_checklist.md, QA quality_checklist.md üretir.'
        : 'Specialist Producer zorunlu yolları: ${required.join(', ')}. Product Manager brief.md, Architect architecture.md, QA quality_checklist.md, DevOps release_checklist.md üretir.';
    return '''Sen DEST-OS ARES Specialist Producer ajanısın.
İstek: $request
Mod: ${mode.name}
Süre: $duration
Stil: $style
Platform: $platform
$contract
Çıktı SADECE geçerli JSON olmalı: {"artifacts":[{"relativePath":"...","content":"...","type":"markdown|other","generatedBy":"SpecialistProducer"}]}
Path yalnızca göreli olmalı. ARES kaynak kodunu değiştirme. Video captions.srt gerçek SRT zaman damgaları içermeli. Sahte render yapılmış gibi yazma.''';
  }

  AresResult<List<CodeArtifact>> _parseArtifacts(String raw) {
    try {
      dynamic decoded = jsonDecode(raw);
      if (decoded is Map) decoded = decoded['artifacts'];
      if (decoded is! List) return const AresFailure<List<CodeArtifact>>('İçerik AI çıktısında artifacts listesi yok.');
      final result = <CodeArtifact>[];
      for (final item in decoded) {
        if (item is! Map || item['relativePath'] is! String || item['content'] is! String) {
          return const AresFailure<List<CodeArtifact>>('İçerik AI çıktısında geçersiz artifact bulundu.');
        }
        final path = item['relativePath'] as String;
        if (_unsafe(path)) return AresFailure<List<CodeArtifact>>('Güvenli olmayan çıktı yolu reddedildi: $path');
        result.add(CodeArtifact(
          relativePath: path,
          content: item['content'] as String,
          type: item['type'] == 'other' ? ArtifactType.other : ArtifactType.markdown,
          generatedBy: item['generatedBy'] is String && (item['generatedBy'] as String).trim().isNotEmpty ? item['generatedBy'] as String : 'SpecialistProducer',
        ));
      }
      return AresSuccess<List<CodeArtifact>>(List.unmodifiable(result));
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('İçerik AI JSON çıktısı bozuk: $error');
    }
  }

  List<String> _contractErrors(ContentMode mode, String contentType, List<CodeArtifact> artifacts) {
    final paths = artifacts.map((a) => a.relativePath).toSet();
    final required = _requiredPaths(mode, contentType);
    final errors = required.where((path) => !paths.contains(path)).map((path) => 'Zorunlu çıktı eksik: $path').toList();
    if (mode == ContentMode.video) {
      final srt = _contentOf(artifacts, 'captions.srt');
      if (!RegExp(r'(?m)^\d+\s*\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}').hasMatch(srt)) {
        errors.add('captions.srt geçerli SRT zaman damgası içermiyor.');
      }
      final checklist = _contentOf(artifacts, 'production_checklist.md');
      if (!checklist.toLowerCase().contains('ffmpeg')) {
        errors.add('production_checklist.md ffmpeg render planı içermiyor.');
      }
    }
    return errors;
  }

  void _appendVideoPipelineArtifacts(
    List<CodeArtifact> artifacts, {
    required String duration,
    required String platform,
  }) {
    final seconds = _parseDurationSeconds(duration);
    final script = _contentOf(artifacts, 'script.md');
    final sceneMatches = RegExp(r'(?im)^#{1,3}\s*(?:sahne|scene)\s*[^\n]*')
        .allMatches(script)
        .length;
    final sceneCount = sceneMatches == 0 ? 1 : sceneMatches.clamp(1, 60).toInt();
    final segment = seconds / sceneCount;
    final timeline = <Map<String, Object>>[];
    for (var i = 0; i < sceneCount; i++) {
      timeline.add(<String, Object>{
        'scene': i + 1,
        'startSeconds': (i * segment).round(),
        'endSeconds': ((i + 1) * segment).round(),
      });
    }
    final renderArgs = const FfmpegCommandBuilder().buildMp4Command(
      outputFileName: 'render.mp4',
      durationSeconds: seconds,
      videoInput: 'assets/video_source.mp4',
    );
    final renderJson = JsonEncoder.withIndent('  ').convert(<String, Object>{
      'executable': 'ffmpeg',
      'arguments': renderArgs,
      'automaticExecution': false,
      'output': 'render.mp4',
      'outputRoot': 'ARES_Output/video/<slug>',
    });
    final finalTimelineJson = JsonEncoder.withIndent('  ').convert(<String, Object>{
      'durationSeconds': seconds,
      'platform': platform,
      'scenes': timeline,
    });
    artifacts.removeWhere((artifact) => <String>{'assets_plan.md', 'timeline.json', 'render_plan.json'}.contains(artifact.relativePath));
    artifacts.addAll(<CodeArtifact>[
      CodeArtifact(
        relativePath: 'assets_plan.md',
        content: '# Assets Plan\n\n- Görsel varlıklar: shot_list.md içindeki her sahne için belirtilen görseller.\n- Ses: voiceover_script.md ve gerektiğinde lisanslı müzik.\n- Kaynaklar kullanıcı tarafından sağlanmalı veya lisansı doğrulanmalıdır.\n- Otomatik indirme yapılmaz.\n',
        type: ArtifactType.markdown,
        generatedBy: 'Architect',
      ),
      CodeArtifact(relativePath: 'timeline.json', content: finalTimelineJson, type: ArtifactType.json, generatedBy: 'Architect'),
      CodeArtifact(relativePath: 'render_plan.json', content: renderJson, type: ArtifactType.json, generatedBy: 'DevOps'),
    ]);
  }

  int _parseDurationSeconds(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    final parsed = int.tryParse(match?.group(1) ?? '') ?? 60;
    return parsed.clamp(1, 86400).toInt();
  }

  List<String> _specialistPaths(ContentMode mode, String contentType) {
    if (mode == ContentMode.video) {
      return const <String>['video_brief.md', 'script.md', 'shot_list.md', 'voiceover_script.md', 'captions.srt', 'thumbnail_prompt.md'];
    }
    switch (contentType) {
      case 'Pazarlama Metni':
        return const <String>['marketing_copy.md', 'variants.md'];
      case 'Post Serisi':
        return const <String>['posts.md', 'captions.md', 'hashtag_plan.md'];
      case 'Ürün Açıklaması':
        return const <String>['product_description.md', 'feature_bullets.md', 'seo_keywords.md'];
      default:
        return const <String>['content.md', 'acceptance_criteria.md'];
    }
  }

  List<String> _requiredPaths(ContentMode mode, String contentType) {
    if (mode == ContentMode.video) {
      return const <String>[
        'video_brief.md', 'script.md', 'shot_list.md', 'voiceover_script.md',
        'captions.srt', 'thumbnail_prompt.md', 'assets_plan.md', 'timeline.json', 'render_plan.json', 'production_checklist.md', 'quality_checklist.md',
      ];
    }
    switch (contentType) {
      case 'Pazarlama Metni':
        return const <String>['brief.md', 'marketing_copy.md', 'variants.md', 'quality_checklist.md', 'release_checklist.md'];
      case 'Post Serisi':
        return const <String>['brief.md', 'posts.md', 'captions.md', 'hashtag_plan.md', 'quality_checklist.md', 'release_checklist.md'];
      case 'Ürün Açıklaması':
        return const <String>['brief.md', 'product_description.md', 'feature_bullets.md', 'seo_keywords.md', 'quality_checklist.md', 'release_checklist.md'];
      default:
        return const <String>['brief.md', 'content.md', 'architecture.md', 'acceptance_criteria.md', 'quality_checklist.md', 'release_checklist.md'];
    }
  }

  String _contentOf(List<CodeArtifact> artifacts, String path) {
    for (final artifact in artifacts) {
      if (artifact.relativePath == path) return artifact.content;
    }
    return '';
  }

  bool _unsafe(String path) {
    final value = path.trim().replaceAll('\\', '/');
    return value.isEmpty || value.startsWith('/') || value == '..' || value.contains('../');
  }
}

```


## `lib/application/video/ffmpeg_command_builder.dart`

```dart
/// Builds only ARES-approved ffmpeg argument lists.
class FfmpegCommandBuilder {
  /// Creates the command builder.
  const FfmpegCommandBuilder();

  /// Builds a safe MP4 render command from already validated local asset paths.
  List<String> buildMp4Command({
    required String outputFileName,
    required int durationSeconds,
    String? videoInput,
    String? audioInput,
  }) {
    final output = _safeFileName(outputFileName, extension: '.mp4');
    if (durationSeconds < 1 || durationSeconds > 86400) {
      throw ArgumentError('Süre 1 ile 86400 saniye arasında olmalıdır.');
    }
    final args = <String>['-y'];
    if (videoInput == null && audioInput == null) {
      throw ArgumentError('Gerçek render için en az bir medya girdisi gerekir.');
    } else {
      if (videoInput != null) args.addAll(<String>['-i', _safeRelativePath(videoInput)]);
      if (audioInput != null) args.addAll(<String>['-i', _safeRelativePath(audioInput)]);
      args.addAll(<String>['-t', '$durationSeconds']);
    }
    args.addAll(<String>['-c:v', 'libx264', '-pix_fmt', 'yuv420p']);
    if (audioInput != null) args.addAll(<String>['-c:a', 'aac']);
    args.add(output);
    return List.unmodifiable(args);
  }

  String _safeFileName(String value, {required String extension}) {
    final trimmed = value.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(trimmed) ||
        !trimmed.toLowerCase().endsWith(extension)) {
      throw ArgumentError('Güvenli olmayan çıktı dosya adı.');
    }
    return trimmed;
  }

  String _safeRelativePath(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty || normalized.startsWith('/') || normalized.contains('../') || normalized == '..') {
      throw ArgumentError('Güvenli olmayan medya yolu.');
    }
    return normalized;
  }
}

```


## `lib/application/video/video_render_service.dart`

```dart
import 'dart:io';

import '../../domain/codegen/code_artifact.dart';
import '../codegen/code_writer_service.dart';
import 'ffmpeg_command_builder.dart';
import '../../infrastructure/video/ffmpeg_command_runner.dart';

/// Creates safe video render plans and optionally executes them with explicit approval.
class VideoRenderService {
  /// Creates the video render service.
  const VideoRenderService({FfmpegCommandBuilder builder = const FfmpegCommandBuilder(), FfmpegCommandRunner runner = const FfmpegCommandRunner()})
      : _builder = builder,
        _runner = runner;

  final FfmpegCommandBuilder _builder;
  final FfmpegCommandRunner _runner;

  /// Writes a deterministic render plan into the supplied video output root.
  Future<CodeWriteResult> writeRenderPlan({required CodeWriterService writer, required String relativeRoot, required int durationSeconds}) async {
    final args = _builder.buildMp4Command(outputFileName: 'render.mp4', durationSeconds: durationSeconds);
    final artifact = CodeArtifact(relativePath: '$relativeRoot/render_plan.json', content: _json(args, durationSeconds), type: ArtifactType.json, generatedBy: 'VideoRenderService');
    return writer.writeArtifacts(<CodeArtifact>[artifact], overwrite: false);
  }

  /// Runs a previously built ARES ffmpeg command after explicit user approval.
  Future<VideoRenderResult> render({required List<String> arguments, required Directory outputRoot, required bool explicitUserApproval}) =>
      _runner.run(arguments: arguments, outputRoot: outputRoot, explicitUserApproval: explicitUserApproval);

  /// Checks local ffmpeg availability.
  Future<FfmpegHealth> healthCheck() => _runner.healthCheck();

  String _json(List<String> args, int duration) {
    final escaped = args.map((value) => '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"').join(', ');
    return '{\n  "durationSeconds": $duration,\n  "executable": "ffmpeg",\n  "arguments": [$escaped],\n  "automaticExecution": false\n}\n';
  }
}

```


## `lib/application/environment/environment_health_service.dart`

```dart
/// Represents one local/remote dependency health state.
class DependencyHealth {
  /// Creates a dependency health state.
  const DependencyHealth({required this.name, required this.ready, required this.message});

  /// Dependency name.
  final String name;
  /// Whether the dependency is usable.
  final bool ready;
  /// Human-readable status or setup guidance.
  final String message;
}

/// Aggregates AI and ffmpeg readiness for the tablet production center.
class EnvironmentHealth {
  /// Creates an immutable environment health snapshot.
  const EnvironmentHealth({required this.localAi, required this.freeAi, required this.ffmpeg});

  /// Local AI state.
  final DependencyHealth localAi;
  /// Free remote AI state.
  final DependencyHealth freeAi;
  /// ffmpeg state.
  final DependencyHealth ffmpeg;
}

/// Application facade for startup dependency health checks.
abstract interface class EnvironmentHealthService {
  /// Checks configured dependencies.
  Future<EnvironmentHealth> check();
}

```


## `lib/infrastructure/environment/environment_health_service_impl.dart`

```dart
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
      return DependencyHealth(name: name, ready: false, message: 'Endpoint veya model adı eksik.');
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
            return DependencyHealth(name: name, ready: modelPresent, message: modelPresent ? 'Hazır • model: $model' : 'Endpoint hazır ancak model listesinde $model bulunamadı.');
          }
        } catch (_) {
          // Try the next OpenAI-compatible health endpoint.
        }
      }
      return DependencyHealth(name: name, ready: false, message: 'Endpoint erişilemiyor veya model listesi alınamıyor.');
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

```


## `lib/infrastructure/video/ffmpeg_command_runner.dart`

```dart
import 'dart:async';
import 'dart:io';

import '../../application/video/ffmpeg_command_builder.dart';

/// Reports whether the local ffmpeg executable can be invoked safely.
class FfmpegHealth {
  /// Creates an ffmpeg health result.
  const FfmpegHealth({required this.available, required this.message});

  /// Whether ffmpeg responded successfully.
  final bool available;

  /// Human-readable status.
  final String message;
}

/// Runs only ARES-generated ffmpeg commands inside a selected output directory.
class FfmpegCommandRunner {
  /// Creates a runner with an optional executable name for testing.
  const FfmpegCommandRunner({this.executable = 'ffmpeg', this.timeout = const Duration(minutes: 10)});

  /// Executable name resolved by the operating system.
  final String executable;

  /// Maximum allowed render duration.
  final Duration timeout;

  /// Checks whether ffmpeg is available.
  Future<FfmpegHealth> healthCheck() async {
    try {
      final result = await Process.run(executable, const <String>['-version'], runInShell: false).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) {
        return const FfmpegHealth(available: true, message: 'ffmpeg hazır.');
      }
      return const FfmpegHealth(available: false, message: 'ffmpeg bulundu ancak çalıştırılamadı.');
    } on TimeoutException {
      return const FfmpegHealth(available: false, message: 'ffmpeg sağlık kontrolü zaman aşımına uğradı.');
    } catch (_) {
      return const FfmpegHealth(available: false, message: 'ffmpeg bulunamadı. Render için ffmpeg kurulmalıdır.');
    }
  }

  /// Executes a prebuilt ARES command only after the caller explicitly enables rendering.
  Future<VideoRenderResult> run({
    required List<String> arguments,
    required Directory outputRoot,
    required bool explicitUserApproval,
  }) async {
    if (!explicitUserApproval) {
      return const VideoRenderResult(success: false, message: 'Render çalıştırmak için açık kullanıcı onayı gerekir.', outputFile: null);
    }
    final executableHealth = await healthCheck();
    if (!executableHealth.available) {
      return VideoRenderResult(success: false, message: executableHealth.message, outputFile: null);
    }
    if (!_safeArguments(arguments)) {
      return const VideoRenderResult(success: false, message: 'Güvenli olmayan ffmpeg komutu reddedildi.', outputFile: null);
    }
    try {
      await outputRoot.create(recursive: true);
      final process = await Process.start(executable, arguments, workingDirectory: outputRoot.path, runInShell: false);
      final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        process.kill(ProcessSignal.sigterm);
        return -1;
      });
      if (exitCode != 0) {
        return VideoRenderResult(success: false, message: 'ffmpeg render başarısız oldu. Çıkış kodu: $exitCode', outputFile: null);
      }
      final outputName = _findOutput(arguments);
      if (outputName == null) {
        return const VideoRenderResult(success: false, message: 'Render çıktısı tanımlı değil.', outputFile: null);
      }
      final output = File('${outputRoot.path}${Platform.pathSeparator}$outputName');
      if (!await output.exists() || await output.length() == 0) {
        return const VideoRenderResult(success: false, message: 'Render tamamlanmadı: gerçek çıktı dosyası oluşmadı.', outputFile: null);
      }
      return VideoRenderResult(success: true, message: 'Render tamamlandı.', outputFile: output.path);
    } catch (error) {
      return VideoRenderResult(success: false, message: 'Render çalıştırılamadı: $error', outputFile: null);
    }
  }

  bool _safeArguments(List<String> args) {
    if (args.isEmpty || args.length > 40) return false;
    const flags = <String>{'-y', '-f', '-i', '-t', '-c:v', '-pix_fmt', '-c:a'};
    const values = <String>{'lavfi', 'color=c=black:s=1280x720:r=30', 'libx264', 'yuv420p', 'aac'};
    for (final arg in args) {
      if (arg.contains(RegExp(r'[;&|`$<>]'))) return false;
    }
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (flags.contains(arg)) continue;
      if (values.contains(arg)) continue;
      if (RegExp(r'^\d+$').hasMatch(arg)) continue;
      if (RegExp(r'^[A-Za-z0-9_./-]+\.(mp4|mov|m4a|wav|mp3)$', caseSensitive: false).hasMatch(arg)) {
        if (arg.startsWith('/') || arg.contains('../') || arg == '..') return false;
        continue;
      }
      return false;
    }
    return args.contains('-i') && args.any((value) => value.toLowerCase().endsWith('.mp4'));
  }

  String? _findOutput(List<String> args) {
    for (var i = args.length - 1; i >= 0; i--) {
      final value = args[i];
      if (value.toLowerCase().endsWith('.mp4')) return value;
    }
    return null;
  }
}

/// Result of an actual ffmpeg invocation.
class VideoRenderResult {
  /// Creates a render result.
  const VideoRenderResult({required this.success, required this.message, required this.outputFile});

  /// Whether a real output file was created.
  final bool success;

  /// Human-readable result message.
  final String message;

  /// Absolute output path when successful.
  final String? outputFile;
}

```


## `lib/application/runtime/production/production_composition_root.dart`

```dart
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
      throw StateError('Content Generation Orchestrator ProductionCompositionRoot'a verilmedi.');
    }
    build();
    return ContentRequestService(_contentGenerationRuntimeModule!);
  }

}

```


## `lib/application/runtime/production/operational_runtime_module.dart`

```dart
import 'runtime_module.dart';

/// Represents an explicitly registered production runtime boundary.
///
/// The module owns lifecycle state and provides a concrete runtime registration
/// point without pretending to execute work that belongs to its dedicated
/// subsystem.
class OperationalRuntimeModule implements RuntimeModule {
  /// Creates a runtime boundary with [name].
  OperationalRuntimeModule(this.name);

  @override
  final String name;

  bool _running = false;

  /// Whether this runtime boundary is active.
  bool get running => _running;

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}

```


## `lib/infrastructure/codegen/file_system_writer.dart`

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/codegen/code_artifact.dart';

/// Tek bir artifact yazma işleminin sonucudur.
class FileWriteResult {
  /// Creates a file-write result.
  const FileWriteResult({
    required this.relativePath,
    required this.written,
    required this.skipped,
  });

  /// Path of the artifact relative to the configured root.
  final String relativePath;

  /// Whether the file was written.
  final bool written;

  /// Whether an existing file caused the write to be skipped.
  final bool skipped;
}

/// Exception raised when a generated file cannot be written safely.
class FileSystemWriterException implements Exception {
  /// Creates a filesystem writer exception.
  const FileSystemWriterException(this.message);

  /// Human-readable failure message.
  final String message;

  @override
  String toString() => message;
}

/// CodeArtifact'leri güvenli biçimde gerçek dosya sistemine yazar.
///
/// [rootDirectory] verilirse yalnızca o kökün altına yazılır. Verilmezse
/// uygulamanın path_provider üzerinden aldığı belgeler dizini kök olarak
/// kullanılır.
class FileSystemWriter {
  /// Creates a secure file writer rooted at [rootDirectory] when supplied.
  FileSystemWriter({Directory? rootDirectory})
      : _rootDirectory = rootDirectory;

  final Directory? _rootDirectory;

  Directory? _resolvedRoot;

  Future<Directory> _root() async {
    final cached = _resolvedRoot;
    if (cached != null) {
      return cached;
    }

    final root = _rootDirectory ?? await getApplicationDocumentsDirectory();
    final absolute = Directory(p.normalize(p.absolute(root.path)));
    await absolute.create(recursive: true);
    _resolvedRoot = absolute;
    return absolute;
  }

  /// Writes one artifact after validating its relative path.
  Future<FileWriteResult> writeArtifact(
    CodeArtifact artifact, {
    bool overwrite = false,
  }) async {
    final root = await _root();
    final safeRelativePath = _validateRelativePath(artifact.relativePath);
    final targetPath = _safeResolve(root.path, safeRelativePath);
    final file = File(targetPath);

    if (await file.exists() && !overwrite) {
      return FileWriteResult(
        relativePath: safeRelativePath,
        written: false,
        skipped: true,
      );
    }

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(artifact.content, flush: true);
    } on FileSystemException catch (error) {
      throw FileSystemWriterException(
        '${safeRelativePath}: dosya yazılamadı: ${error.message}',
      );
    }

    return FileWriteResult(
      relativePath: safeRelativePath,
      written: true,
      skipped: false,
    );
  }

  String _validateRelativePath(String rawPath) {
    final value = rawPath.trim();
    if (value.isEmpty) {
      throw const FileSystemWriterException('Boş dosya yolu yazılamaz.');
    }
    if (p.isAbsolute(value)) {
      throw FileSystemWriterException(
        'Path traversal engellendi: mutlak yol kullanılamaz: $value',
      );
    }

    final normalized = p.normalize(value);
    if (normalized == '.' || normalized == '..' || normalized.startsWith('..${p.separator}')) {
      throw FileSystemWriterException(
        'Path traversal engellendi: kök dizinin dışına çıkış: $value',
      );
    }

    return normalized;
  }

  String _safeResolve(String rootPath, String relativePath) {
    final root = p.normalize(p.absolute(rootPath));
    final candidate = p.normalize(p.join(root, relativePath));
    final relativeToRoot = p.relative(candidate, from: root);

    if (relativeToRoot == '..' ||
        relativeToRoot.startsWith('..${p.separator}') ||
        p.isAbsolute(relativeToRoot)) {
      throw FileSystemWriterException(
        'Path traversal engellendi: hedef kök dizinin dışında: $relativePath',
      );
    }

    return candidate;
  }
}

```


## `PROJECT_SUMMARY.md`

```markdown
# DEST-OS ARES Production Summary

## Üretim merkezleri

ARES tablet ana ekranından üç mod açılır:

1. Mobil Uygulama Üret
2. Video İçerik Üret
3. Genel İçerik Üret

## Mobil akış

Yüksek seviye fikir → ProjectSpec → Scaffold → ajanlar → gerçek Local/Free AI → Validator/Self-Healing → Build Readiness → güvenli ayrı output root.

Zorunlu proje çıktıları: `lib/main.dart`, `lib/app/app.dart`, domain/application/presentation Dart dosyaları, `pubspec.yaml`, `analysis_options.yaml`, `README.md`, `BUILD_READY.md`, `SMOKE_CHECKLIST.md`.

## Video akışı

Yüksek seviye fikir + süre + stil + platform → Product Manager → Architect → Specialist Producer → QA → DevOps → kalite kapısı → ayrı video output.

Zorunlu dosyalar: `video_brief.md`, `script.md`, `shot_list.md`, `voiceover_script.md`, `captions.srt`, `thumbnail_prompt.md`, `production_checklist.md`, `assets_plan.md`, `timeline.json`, `render_plan.json`.

Gerçek render yalnız kullanıcı açıkça başlatırsa çalışır. ffmpeg yoksa render yapılmış kabul edilmez.

## AI sırası

Local Ollama/LM Studio → yapılandırılmış Free/Limited-Free endpoint → açık onay gerektiren Paid/Unknown kapısı. Üretim UI'sı Mock'a sessizce düşmez.

## Güvenlik

PaidAiRuntimeGate/DecisionEngine, path traversal koruması, ayrı output root, shell kapalı ffmpeg çalıştırma, timeout ve allowlist korunur.

## Ortam bağımlılıkları

Gerçek AI için Ollama/LM Studio veya doğrulanmış ücretsiz endpoint erişilebilir olmalıdır. APK/analyze/test için Flutter SDK gerekir. Gerçek video render için ffmpeg ve kullanıcı tarafından sağlanan/lisansı doğrulanmış medya girdileri gerekir.

## Son kontrol listesi

- [x] Tablet üretim merkezi
- [x] Mobil üretim
- [x] Video paket üretimi
- [x] Genel içerik üretimi
- [x] Local/Free AI fallback
- [x] Sessiz Mock yok
- [x] Build readiness
- [x] Ayrı mobil output root
- [x] Ayrı video output root
- [x] ffmpeg komut allowlist'i
- [x] Açık render onayı
- [x] Path traversal koruması
- [x] Paid/unknown AI kapısı
- [x] Health/status kartı
- [x] Edge-case testleri

```


## `test/application/codegen/build_readiness_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/application/codegen/build_readiness_service.dart';
import '../../../lib/domain/codegen/artifact_type.dart';
import '../../../lib/domain/codegen/code_artifact.dart';

void main() {
  test('tam Flutter iskeleti build-ready olur', () {
    const artifacts = <CodeArtifact>[
      CodeArtifact(relativePath: 'lib/main.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/domain/model.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/application/service.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/presentation/home.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'pubspec.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'analysis_options.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'README.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'BUILD_READY.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'SMOKE_CHECKLIST.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
    ];
    expect(const BuildReadinessService().evaluate(artifacts).ready, isTrue);
  });

  test('eksik application dosyası build-ready sayılmaz', () {
    const artifacts = <CodeArtifact>[
      CodeArtifact(relativePath: 'lib/main.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/domain/model.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'lib/presentation/home.dart', content: '', type: ArtifactType.dart, generatedBy: 'test'),
      CodeArtifact(relativePath: 'pubspec.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'analysis_options.yaml', content: '', type: ArtifactType.yaml, generatedBy: 'test'),
      CodeArtifact(relativePath: 'README.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'BUILD_READY.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
      CodeArtifact(relativePath: 'SMOKE_CHECKLIST.md', content: '', type: ArtifactType.markdown, generatedBy: 'test'),
    ];
    expect(const BuildReadinessService().evaluate(artifacts).ready, isFalse);
  });
}

```


## `test/application/video/video_render_service_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/infrastructure/video/ffmpeg_command_runner.dart';

void main() {
  test('render açık onay olmadan çalışmaz', () async {
    final root = await Directory.systemTemp.createTemp('ares_render_guard_');
    addTearDown(() => root.delete(recursive: true));
    final result = await const FfmpegCommandRunner().run(
      arguments: const <String>['-y', '-i', 'assets/video_source.mp4', 'render.mp4'],
      outputRoot: root,
      explicitUserApproval: false,
    );
    expect(result.success, isFalse);
    expect(result.message, contains('açık kullanıcı onayı'));
  });
}

```


## `test/infrastructure/video/ffmpeg_command_builder_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/application/video/ffmpeg_command_builder.dart';

void main() {
  test('ffmpeg komutu güvenli ve shell bağımsız argümanlardan oluşur', () {
    final args = const FfmpegCommandBuilder().buildMp4Command(
      outputFileName: 'render.mp4',
      durationSeconds: 60,
      videoInput: 'assets/video_source.mp4',
    );
    expect(args, contains('assets/video_source.mp4'));
    expect(args.last, 'render.mp4');
    expect(args.any((value) => value.contains(';')), isFalse);
  });

  test('path traversal ve enjeksiyon denemesi reddedilir', () {
    expect(
      () => const FfmpegCommandBuilder().buildMp4Command(
        outputFileName: '../render.mp4',
        durationSeconds: 60,
        videoInput: 'assets/video_source.mp4',
      ),
      throwsArgumentError,
    );
    expect(
      () => const FfmpegCommandBuilder().buildMp4Command(
        outputFileName: 'render.mp4;touch-pwned.mp4',
        durationSeconds: 60,
        videoInput: 'assets/video_source.mp4',
      ),
      throwsArgumentError,
    );
  });
}

```


## `test/infrastructure/environment/environment_health_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/infrastructure/environment/environment_health_service_impl.dart';

void main() {
  test('eksik yerel AI yapılandırması hazır görünmez', () async {
    final service = const DefaultEnvironmentHealthService(localBaseUrl: '', localModel: 'qwen3:4b', freeApiKey: null);
    final health = await service.check();
    expect(health.localAi.ready, isFalse);
    expect(health.localAi.message, contains('Endpoint'));
  });
}

```


## `test/infrastructure/codegen/file_system_writer_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/domain/codegen/artifact_type.dart';
import '../../../lib/domain/codegen/code_artifact.dart';
import '../../../lib/infrastructure/codegen/file_system_writer.dart';

void main() {
  test('blocks path traversal', () async {
    final root = await Directory.systemTemp.createTemp('ares_writer_test_');
    addTearDown(() => root.delete(recursive: true));

    final writer = FileSystemWriter(rootDirectory: root);
    const artifact = CodeArtifact(
      relativePath: '../outside.txt',
      content: 'blocked',
      type: ArtifactType.other,
      generatedBy: 'test',
    );

    expect(
      () => writer.writeArtifact(artifact),
      throwsA(isA<FileSystemWriterException>()),
    );
  });

  test('yazma kökü kaynak ağacından ayrıdır', () async {
    final root = await Directory.systemTemp.createTemp('ares_output_root_test_');
    addTearDown(() => root.delete(recursive: true));
    final writer = FileSystemWriter(rootDirectory: root);
    final result = await writer.writeArtifact(
      const CodeArtifact(
        relativePath: 'ARES_Output/video/demo/README.md',
        content: 'output',
        type: ArtifactType.markdown,
        generatedBy: 'test',
      ),
    );
    expect(result.written, isTrue);
    expect(await File('${root.path}/ARES_Output/video/demo/README.md').readAsString(), 'output');
  });
}

```
