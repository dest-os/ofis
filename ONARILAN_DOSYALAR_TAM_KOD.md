# DEST-OS ARES — Ön Yayın Analiz Onarımı

Bu dosya, bu turda değiştirilen dosyaların tam içeriklerini içerir.

## `lib/application/codegen/code_validator_service.dart`

```dart
import 'dart:convert';

import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';

/// Kod üretim çıktısının temel doğrulama sonucudur.
class CodeValidationReport {
  /// Creates an immutable validation report.
  CodeValidationReport({
    required List<String> errors,
    required List<String> suggestedActions,
  })  : errors = List.unmodifiable(errors),
        suggestedActions = List.unmodifiable(suggestedActions);

  /// Validation errors that must be resolved.
  final List<String> errors;

  /// Suggested corrective actions associated with the errors.
  final List<String> suggestedActions;

  /// Whether no validation errors were found.
  bool get isValid => errors.isEmpty;
}

/// Üretilen artifact'lerin temel ve güvenli doğrulamasını yapar.
///
/// Bu servis tam bir Dart analyzer yerine üretim hattının erken aşamasında
/// çalışacak hafif bir doğrulama katmanıdır. Amaç belirgin bozuk çıktıları,
/// eksik referansları ve hatalı pubspec yapılarını LLM'e geri göndermeden önce
/// yakalamaktır.
class CodeValidatorService {
  /// Creates a lightweight code validator.
  const CodeValidatorService();

  /// Validates generated artifacts without invoking the full Dart analyzer.
  CodeValidationReport validate(List<CodeArtifact> artifacts) {
    final errors = <String>[];
    final actions = <String>[];
    final paths = <String>{};

    for (final artifact in artifacts) {
      final path = artifact.relativePath.trim();
      if (path.isEmpty) {
        errors.add('Artifact yolu boş.');
        actions.add('Artifact için geçerli bir relativePath üret.');
        continue;
      }

      if (!paths.add(path)) {
        errors.add('Aynı artifact yolu birden fazla kez üretildi: $path');
        actions.add('$path için tek bir artifact bırak.');
      }

      if (_isUnsafePath(path)) {
        errors.add('Güvenli olmayan artifact yolu: $path');
        actions.add('$path için yalnızca proje kökü altındaki göreli yolu kullan.');
      }

      if (artifact.type == ArtifactType.dart || path.endsWith('.dart')) {
        _validateDart(
          artifact,
          paths: paths,
          artifacts: artifacts,
          errors: errors,
          actions: actions,
        );
      }
    }

    final pubspec = _findArtifact(artifacts, 'pubspec.yaml');
    if (pubspec != null) {
      _validatePubspec(pubspec, errors, actions);
    }

    _validateReferences(artifacts, errors, actions);

    return CodeValidationReport(
      errors: errors,
      suggestedActions: actions,
    );
  }

  void _validateDart(
    CodeArtifact artifact, {
    required Set<String> paths,
    required List<CodeArtifact> artifacts,
    required List<String> errors,
    required List<String> actions,
  }) {
    final content = artifact.content;
    final path = artifact.relativePath;

    final balanceError = _checkBalancedDelimiters(content);
    if (balanceError != null) {
      errors.add('$path: $balanceError');
      actions.add('$path: Parantez, köşeli parantez ve süslü parantezleri dengele.');
    }

    final importLines = RegExp(
      r'''^\s*import\s+['"]([^'"]+)['"]\s*;''',
      multiLine: true,
    ).allMatches(content);

    for (final match in importLines) {
      final importPath = match.group(1);
      if (importPath == null) {
        continue;
      }
      if (importPath.startsWith('dart:') || importPath.startsWith('package:flutter/')) {
        continue;
      }
      if (importPath.startsWith('package:')) {
        continue;
      }
      if (importPath.startsWith('.')) {
        final target = _resolveRelativeImport(path, importPath);
        if (!_containsPath(artifacts, target)) {
          errors.add('$path: Eksik relative import: $importPath -> $target');
          actions.add('$path: $importPath importunu mevcut bir artifact'e yönelt veya gerekli dosyayı üret.');
        }
      }
    }
  }

  void _validatePubspec(
    CodeArtifact artifact,
    List<String> errors,
    List<String> actions,
  ) {
    final content = artifact.content;
    if (content.trim().isEmpty) {
      errors.add('pubspec.yaml boş.');
      actions.add('Geçerli bir pubspec.yaml içeriği üret.');
      return;
    }

    final lines = const LineSplitter().convert(content);
    var hasName = false;
    var hasEnvironment = false;
    var hasDependencies = false;
    var hasFlutter = false;
    var indentationError = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      if (!trimmed.contains(':') && !trimmed.startsWith('-')) {
        errors.add('pubspec.yaml: YAML satırı anahtar/değer yapısında değil: $line');
        actions.add('pubspec.yaml içindeki satırı geçerli YAML anahtar/değer biçimine getir.');
      }
      final leadingSpaces = line.length - line.trimLeft().length;
      if (leadingSpaces % 2 != 0) {
        indentationError = true;
      }
      if (trimmed.startsWith('name:')) hasName = true;
      if (trimmed.startsWith('environment:')) hasEnvironment = true;
      if (trimmed.startsWith('dependencies:')) hasDependencies = true;
      if (trimmed == 'flutter:' || trimmed.startsWith('flutter:')) hasFlutter = true;
    }

    if (!hasName) {
      errors.add('pubspec.yaml: name alanı eksik.');
      actions.add('pubspec.yaml içine geçerli bir name alanı ekle.');
    }
    if (!hasEnvironment) {
      errors.add('pubspec.yaml: environment alanı eksik.');
      actions.add('pubspec.yaml içine Dart SDK environment alanı ekle.');
    }
    if (!hasDependencies) {
      errors.add('pubspec.yaml: dependencies alanı eksik.');
      actions.add('pubspec.yaml içine dependencies bölümü ekle.');
    }
    if (!hasFlutter) {
      errors.add('pubspec.yaml: Flutter bağımlılığı bulunamadı.');
      actions.add('dependencies altında Flutter SDK bağımlılığını tanımla.');
    }
    if (indentationError) {
      errors.add('pubspec.yaml: tutarsız girinti bulundu.');
      actions.add('pubspec.yaml girintilerini tutarlı iki boşluk olacak şekilde düzelt.');
    }
  }

  void _validateReferences(
    List<CodeArtifact> artifacts,
    List<String> errors,
    List<String> actions,
  ) {
    final paths = artifacts.map((artifact) => artifact.relativePath).toSet();
    final dartFiles = artifacts.where(
      (artifact) => artifact.type == ArtifactType.dart || artifact.relativePath.endsWith('.dart'),
    );

    for (final artifact in dartFiles) {
      final packageMatches = RegExp(
        r'''package:([A-Za-z0-9_\-]+)/([^'";]+)''',
      ).allMatches(artifact.content);
      for (final match in packageMatches) {
        final packageName = match.group(1);
        final packagePath = match.group(2);
        if (packageName == null || packagePath == null) continue;
        final pubspec = _findArtifact(artifacts, 'pubspec.yaml');
        if (pubspec != null && packageName == _readPackageName(pubspec.content)) {
          final internalPath = packagePath.replaceAll('\\', '/');
          if (!paths.contains(internalPath)) {
            errors.add(
              '${artifact.relativePath}: package içi referans bulunamadı: package:$packageName/$internalPath',
            );
            actions.add(
              '${artifact.relativePath}: package içi referansı mevcut artifact yoluna bağla veya dosyayı üret.',
            );
          }
        }
      }
    }
  }

  String? _readPackageName(String content) {
    final match = RegExp(r'^\s*name:\s*([^\s#]+)', multiLine: true).firstMatch(content);
    return match?.group(1);
  }

  CodeArtifact? _findArtifact(List<CodeArtifact> artifacts, String path) {
    for (final artifact in artifacts) {
      if (artifact.relativePath == path) return artifact;
    }
    return null;
  }

  bool _containsPath(List<CodeArtifact> artifacts, String target) {
    return artifacts.any((artifact) => artifact.relativePath == target);
  }

  String _resolveRelativeImport(String sourcePath, String importPath) {
    final sourceSegments = sourcePath.replaceAll('\\', '/').split('/');
    sourceSegments.removeLast();
    for (final segment in importPath.replaceAll('\\', '/').split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (sourceSegments.isNotEmpty) sourceSegments.removeLast();
      } else {
        sourceSegments.add(segment);
      }
    }
    return sourceSegments.join('/');
  }

  String? _checkBalancedDelimiters(String content) {
    final stack = <String>[];
    const pairs = <String, String>{
      ')': '(',
      ']': '[',
      '}': '{',
    };

    var inSingleQuote = false;
    var inDoubleQuote = false;
    var escaped = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if ((inSingleQuote || inDoubleQuote) && char == '\\') {
        escaped = true;
        continue;
      }
      if (!inDoubleQuote && char == "'") {
        inSingleQuote = !inSingleQuote;
        continue;
      }
      if (!inSingleQuote && char == '"') {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }
      if (inSingleQuote || inDoubleQuote) continue;

      if (char == '(' || char == '[' || char == '{') {
        stack.add(char);
      } else if (pairs.containsKey(char)) {
        if (stack.isEmpty || stack.removeLast() != pairs[char]) {
          return 'Dengesiz "$char" parantezi bulundu (karakter $i).';
        }
      }
    }

    if (inSingleQuote || inDoubleQuote) {
      return 'Kapatılmamış string bulundu.';
    }
    if (stack.isNotEmpty) {
      return 'Kapatılmamış "${stack.last}" parantezi bulundu.';
    }
    return null;
  }

  bool _isUnsafePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.startsWith('/') ||
        normalized.startsWith('~/') ||
        normalized.split('/').contains('..') ||
        RegExp(r'^[A-Za-z]:/').hasMatch(normalized);
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

## `lib/application/codegen/code_generation_orchestrator.dart`

```dart
import '../../application/events/event_bus.dart';
import '../ceo/ceo_self_heal_service.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/codegen/generation_plan.dart';
import '../../domain/codegen/generation_result.dart';
import '../../domain/codegen/project_spec.dart';
import '../../domain/events/event_envelope.dart';
import '../../domain/events/event_type.dart';
import '../../infrastructure/codegen/llm_code_generator.dart';
import 'build_readiness_service.dart';
import 'code_validator_service.dart';
import 'code_writer_service.dart';
import 'project_scaffold_service.dart';
import 'prompt_builder_service.dart';

/// Kod Üretim Motorunun ana uygulama orkestratörüdür.
///
/// [ProjectSpec] girdisini üretim planına dönüştürür; iskelet, domain,
/// application ve presentation artifact'lerini üretir; doğrulama ve en fazla
/// üç self-healing turu uygular; ardından dosyaları güvenli writer katmanına
/// teslim eder ve son doğrulamayı yapar. LLM çağrıları yalnızca verilen
/// [LlmCodeGenerator] üzerinden yapılır; bu sınıf ücretli AI güvenlik kapısını
/// bypass etmez.
class CodeGenerationOrchestrator {
  /// Creates a code-generation orchestrator from configured services.
  CodeGenerationOrchestrator({
    required ProjectScaffoldService scaffoldService,
    required PromptBuilderService promptBuilder,
    required LlmCodeGenerator llmCodeGenerator,
    required CodeWriterService codeWriter,
    required CodeValidatorService validator,
    this.eventBus,
    this.logger,
    this.aiCostClass = AiCostClass.unknown,
    this.buildReadinessService = const BuildReadinessService(),
    this.provider,
    this.model,
    CeoSelfHealService? ceoSelfHealService,
  })  : _scaffoldService = scaffoldService,
        _promptBuilder = promptBuilder,
        _llmCodeGenerator = llmCodeGenerator,
        _codeWriter = codeWriter,
        _validator = validator,
        ceoSelfHealService = ceoSelfHealService ?? CeoSelfHealService(
          llmCodeGenerator: llmCodeGenerator,
          costClass: aiCostClass,
          provider: provider,
          model: model,
        );

  final ProjectScaffoldService _scaffoldService;
  final PromptBuilderService _promptBuilder;
  final LlmCodeGenerator _llmCodeGenerator;
  final CodeWriterService _codeWriter;
  final CodeValidatorService _validator;

  /// CEO self-heal servisi; mevcut AI maliyet güvenlik politikasını kullanır.
  final CeoSelfHealService ceoSelfHealService;

  /// Deterministic build-readiness checker used before the final write.
  final BuildReadinessService buildReadinessService;

  /// Optional Event Bus used for lifecycle notifications.
  final EventBus? eventBus;

  /// Optional diagnostic logger.
  final void Function(String message)? logger;

  /// Cost classification required for every LLM call. Unknown is the safe default.
  final AiCostClass aiCostClass;

  /// Optional provider identifier passed to the configured LLM gateway.
  final String? provider;

  /// Optional model identifier passed to the configured LLM gateway.
  final String? model;

  /// Maximum number of retries after the first LLM attempt for a phase.
  static const int maxRetriesPerStep = 3;

  /// Maximum number of validation repair attempts.
  static const int maxSelfHealingAttempts = 3;

  /// Generates, validates, repairs when necessary, and safely writes a project.
  ///
  /// [onProgress] receives short Turkish status messages so the presentation
  /// layer can show live progress without knowing anything about the engine's
  /// internal services.
  Future<GenerationResult> generate(
    ProjectSpec spec, {
    void Function(String status)? onProgress,
  }) async {
    final startedAt = DateTime.now();
    final logs = <String>[];
    final errors = <String>[];
    final suggestions = <String>[];
    final artifacts = <CodeArtifact>[];
    var retryCount = 0;
    var selfHealingCount = 0;
    final ceoNotes = <String>[];

    Future<void> log(String message) async {
      final entry = '[${DateTime.now().toIso8601String()}] $message';
      logs.add(entry);
      logger?.call(entry);
      onProgress?.call(message);
    }

    await log('İstek: Kod üretimi başlatıldı.');
    await _publish(
      type: EventType.systemStarted,
      message: 'code_generation_started',
      projectName: spec.projectName,
    );

    final plan = _createPlan(spec);
    await log('Plan: System Architect ajanı için ${plan.steps.length} üretim adımı hazır.');

    List<CodeArtifact> scaffold;
    try {
      await log('Scaffold: Flutter proje iskeleti oluşturuluyor.');
      scaffold = _scaffoldService.generate(spec);
    } catch (error) {
      final message = 'Proje iskeleti üretilemedi: $error';
      errors.add(message);
      await log('Hata: $message');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    artifacts.addAll(scaffold);
    await log('Scaffold: ${scaffold.length} artifact oluşturuldu.');

    await log('Doğrulama: proje iskeleti kontrol ediliyor.');
    final scaffoldValidation = _validator.validate(scaffold);
    if (!scaffoldValidation.isValid) {
      errors.addAll(scaffoldValidation.errors);
      suggestions.addAll(scaffoldValidation.suggestedActions);
      await log('Hata: proje iskeleti doğrulaması başarısız.');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    const phases = <_GenerationPhase>[
      _GenerationPhase(
        name: 'Product Manager',
        role: CodegenAgentRole.productManager,
        directory: 'docs/product/',
      ),
      _GenerationPhase(
        name: 'System Architect',
        role: CodegenAgentRole.architect,
        directory: 'docs/architecture/',
      ),
      _GenerationPhase(
        name: 'Domain',
        role: CodegenAgentRole.flutterDeveloper,
        directory: 'lib/domain/',
      ),
      _GenerationPhase(
        name: 'Application',
        role: CodegenAgentRole.flutterDeveloper,
        directory: 'lib/application/',
      ),
      _GenerationPhase(
        name: 'Presentation',
        role: CodegenAgentRole.flutterDeveloper,
        directory: 'lib/presentation/',
      ),
      _GenerationPhase(
        name: 'QA Engineer',
        role: CodegenAgentRole.qaEngineer,
        directory: 'test/generated/',
      ),
      _GenerationPhase(
        name: 'DevOps / Release',
        role: CodegenAgentRole.devOps,
        directory: 'docs/release/',
      ),
    ];

    for (final phase in phases) {
      await log('${phase.name}: üretim başladı.');
      final phaseResult = await _runPhaseWithRetry(
        phase: phase,
        spec: spec,
        existingArtifacts: artifacts,
        onLog: log,
      );
      retryCount += phaseResult.retries;

      final result = phaseResult.result;
      if (result is AresFailure<List<CodeArtifact>>) {
        final message = '${phase.name}: ${result.message}';
        errors.add(message);
        suggestions.addAll(_aiSetupSuggestions());
        await log('Hata: $message');
        return _result(
          success: false,
          artifacts: artifacts,
          errors: errors,
          suggestions: suggestions,
          logs: logs,
          retryCount: retryCount,
          selfHealingCount: selfHealingCount,
          startedAt: startedAt,
          ceoNotes: ceoNotes,
        );
      }

      final generated = (result as AresSuccess<List<CodeArtifact>>).value;
      await log('Doğrulama: ${phase.name} çıktısı kontrol ediliyor.');
      final validation = _validator.validate(<CodeArtifact>[...artifacts, ...generated]);

      if (!validation.isValid) {
        suggestions.addAll(validation.suggestedActions);
        await log('${phase.name}: doğrulama hatası bulundu; self-healing başlıyor.');
        final healed = await _selfHeal(
          phase: phase,
          spec: spec,
          allArtifacts: artifacts,
          phaseArtifacts: generated,
          initialReport: validation,
          onLog: log,
        );
        selfHealingCount += healed.attempts;
        ceoNotes.addAll(healed.ceoNotes);

        if (!healed.success) {
          errors.addAll(healed.errors.map((error) => '${phase.name}: $error'));
          suggestions.addAll(healed.suggestedActions);
          await log('${phase.name}: self-healing başarısız.');
          return _result(
            success: false,
            artifacts: artifacts,
            errors: errors,
            suggestions: suggestions,
            logs: logs,
            retryCount: retryCount,
            selfHealingCount: selfHealingCount,
            startedAt: startedAt,
          );
        }

        artifacts
          ..removeWhere((artifact) =>
              healed.replacedPaths.contains(artifact.relativePath))
          ..addAll(healed.artifacts);
        await log('${phase.name}: self-healing başarılı.');
      } else {
        artifacts.addAll(generated);
      }

      await log('${phase.name}: üretim tamamlandı.');
    }

    await log('Doğrulama: tüm proje artifact\'leri kontrol ediliyor.');
    final projectHealing = await _selfHealWholeProject(
      spec: spec,
      artifacts: artifacts,
      onLog: log,
    );
    selfHealingCount += projectHealing.attempts;
    ceoNotes.addAll(projectHealing.ceoNotes);

    if (!projectHealing.success) {
      errors.addAll(projectHealing.errors);
      suggestions.addAll(projectHealing.suggestedActions);
      await log('Hata: proje geneli self-healing tamamlanamadı.');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    final readiness = buildReadinessService.evaluate(artifacts);
    await log(readiness.ready
        ? 'QA: build hazırlık kontrolü başarılı.'
        : 'QA: build hazırlık kontrolünde eksik veya kırık öğe bulundu.');
    artifacts.add(
      CodeArtifact(
        relativePath: 'docs/BUILD_READINESS.md',
        content: readiness.toMarkdown(),
        type: ArtifactType.markdown,
        generatedBy: 'DevOps',
      ),
    );
    if (!readiness.ready) {
      errors.add('Build hazırlık kontrolü başarısız.');
      suggestions.addAll(readiness.checks.where((check) => check.startsWith('✗')));
    }

    await log('Yazma: güvenli proje köküne dosyalar yazılıyor.');
    late final CodeWriteResult writeResult;
    try {
      final outputArtifacts = artifacts
          .map((artifact) => artifact.copyWith(
                relativePath: 'ARES_Generated_Projects/${_safeOutputFolder(spec.packageName)}/${artifact.relativePath}',
              ))
          .toList(growable: false);
      writeResult = await _codeWriter.writeArtifacts(
        outputArtifacts,
        overwrite: false,
      );
    } catch (error) {
      final message = 'Dosya yazma servisi beklenmeyen bir hata verdi: $error';
      errors.add(message);
      await log('Hata: $message');
      return _result(
        success: false,
        artifacts: artifacts,
        errors: errors,
        suggestions: suggestions,
        logs: logs,
        retryCount: retryCount,
        selfHealingCount: selfHealingCount,
        startedAt: startedAt,
        ceoNotes: ceoNotes,
      );
    }

    if (writeResult.errors.isNotEmpty) {
      errors.addAll(writeResult.errors);
      await log('Yazma: ${writeResult.errors.length} hata bildirildi.');
    } else {
      await log('Yazma: ${writeResult.writtenPaths.length} dosya başarıyla yazıldı.');
    }

    await log('Doğrulama: son artifact kontrolü yapılıyor.');
    final finalValidation = _validator.validate(artifacts);
    if (!finalValidation.isValid) {
      errors.addAll(finalValidation.errors);
      suggestions.addAll(finalValidation.suggestedActions);
      await log('Hata: son doğrulama başarısız.');
    } else {
      await log('Doğrulama: son kontrol başarılı.');
    }

    final success = errors.isEmpty && finalValidation.isValid && readiness.ready;
    await log(success
        ? 'Tamam: kod üretimi başarıyla tamamlandı.'
        : 'Tamam: kod üretimi hatayla tamamlandı.');

    await _publish(
      type: success ? EventType.systemStopped : EventType.securityAlert,
      message: success ? 'code_generation_completed' : 'code_generation_failed',
      projectName: spec.projectName,
    );

    return _result(
      success: success,
      artifacts: artifacts,
      errors: errors,
      suggestions: suggestions,
      logs: logs,
      retryCount: retryCount,
      selfHealingCount: selfHealingCount,
      startedAt: startedAt,
      ceoNotes: ceoNotes,
      extraMetrics: <String, Object?>{
        'buildReady': readiness.ready,
        'hasMain': readiness.hasMain,
        'hasPubspec': readiness.hasPubspec,
        'hasScreen': readiness.hasScreen,
        'hasAnalysisOptions': readiness.hasAnalysisOptions,
        'brokenCriticalImportCount': readiness.brokenCriticalImports.length,
        'outputRoot': 'ARES_Generated_Projects/${_safeOutputFolder(spec.packageName)}',
      },
    );
  }

  List<String> _aiSetupSuggestions() => const <String>[
        'Ollama veya LM Studio kurulu ve erişilebilir olmalı.',
        'ARES_LOCAL_AI_BASE_URL ve ARES_LOCAL_AI_MODEL değerlerini kontrol edin.',
        'Yerel AI yoksa ARES_FREE_AI_BASE_URL ve ARES_FREE_AI_MODEL ile doğrulanmış ücretsiz endpoint tanımlayın.',
      ];

  String _safeOutputFolder(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'generated_app' : normalized;
  }

  GenerationPlan _createPlan(ProjectSpec spec) {
    return GenerationPlan(
      projectName: 'runtime',
      steps: <GenerationStep>[
        GenerationStep(id: 'scaffold', name: 'Scaffold', description: 'Proje iskeletini oluştur.', order: 1, required: true),
        GenerationStep(id: 'product_manager', name: 'Product Manager', description: 'İsteği ve kabul kriterlerini netleştir.', order: 2, required: true),
        GenerationStep(id: 'architect', name: 'System Architect', description: 'Mimari ve klasör kararlarını üret.', order: 3, required: true),
        GenerationStep(id: 'domain', name: 'Domain', description: 'Domain dosyalarını üret.', order: 4, required: true),
        GenerationStep(id: 'application', name: 'Application', description: 'Application dosyalarını üret.', order: 5, required: true),
        GenerationStep(id: 'presentation', name: 'Presentation', description: 'Presentation dosyalarını üret.', order: 6, required: true),
        GenerationStep(id: 'qa', name: 'QA Engineer', description: 'Test ve kalite çıktıları üret.', order: 7, required: true),
        GenerationStep(id: 'devops', name: 'DevOps / Release', description: 'Build hazırlık ve release belgelerini üret.', order: 8, required: true),
        GenerationStep(id: 'validation', name: 'Doğrulama', description: 'Çıktıları doğrula ve gerektiğinde iyileştir.', order: 9, required: true),
        GenerationStep(id: 'write', name: 'Yazma', description: 'Dosyaları güvenli köke yaz.', order: 10, required: true),
      ],
    ).copyWith(projectName: spec.projectName);
  }

  Future<_PhaseResult> _runPhaseWithRetry({
    required _GenerationPhase phase,
    required ProjectSpec spec,
    required List<CodeArtifact> existingArtifacts,
    required Future<void> Function(String message) onLog,
  }) async {
    var retries = 0;
    AresResult<List<CodeArtifact>>? lastFailure;

    for (var attempt = 0; attempt <= maxRetriesPerStep; attempt++) {
      if (attempt > 0) {
        retries++;
        await onLog('${phase.name}: tekrar denemesi $attempt/${maxRetriesPerStep}.');
      }

      final prompt = _promptBuilder.build(
        role: phase.role,
        projectSpec: spec,
        relevantFiles: _relevantFiles(existingArtifacts, phase.directory),
        fileExcerpts: _previousOutputExcerpts(existingArtifacts, phase.directory),
      );

      try {
        final result = await _llmCodeGenerator.generate(
          prompt,
          costClass: aiCostClass,
          provider: provider,
          model: model,
        );
        if (result is AresSuccess<List<CodeArtifact>>) {
          final ownershipError = _validatePhaseOwnership(phase, result.value);
          if (ownershipError == null) {
            return _PhaseResult(result: result, retries: retries);
          }
          lastFailure = AresFailure<List<CodeArtifact>>(ownershipError);
          await onLog('Hata: $ownershipError');
        } else {
          lastFailure = result;
        }
      } catch (error) {
        lastFailure = AresFailure<List<CodeArtifact>>(
          'LLM çağrısı beklenmeyen bir hata verdi: $error',
        );
      }
    }

    return _PhaseResult(
      result: lastFailure ?? const AresFailure<List<CodeArtifact>>('LLM üretimi başarısız.'),
      retries: retries,
    );
  }

  Future<_HealingResult> _selfHeal({
    required _GenerationPhase phase,
    required ProjectSpec spec,
    required List<CodeArtifact> allArtifacts,
    required List<CodeArtifact> phaseArtifacts,
    required CodeValidationReport initialReport,
    required Future<void> Function(String message) onLog,
  }) async {
    var current = List<CodeArtifact>.from(phaseArtifacts);
    var report = initialReport;
    final notes = <String>[];
    final seenSignatures = <String>{};

    for (var attempt = 1; attempt <= CeoSelfHealService.maxAttempts; attempt++) {
      final signature = '${report.errors.join('|')}|${report.suggestedActions.join('|')}';
      if (!seenSignatures.add(signature)) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: current.map((a) => a.relativePath).toSet(),
          errors: const <String>['Aynı hata tekrarlandı; CEO aynı düzeltmeyi sonsuz kez denemedi.'],
          suggestedActions: report.suggestedActions,
          attempts: attempt - 1,
          ceoNotes: notes,
        );
      }

      final diagnosis = ceoSelfHealService.diagnose(report);
      notes.add('Deneme $attempt: $diagnosis');
      await onLog('CEO: $diagnosis');
      await onLog('CEO: düzeltme denemesi $attempt/${CeoSelfHealService.maxAttempts}.');

      final result = await ceoSelfHealService.repair(
        spec: spec,
        role: phase.role,
        artifacts: current,
        report: report,
      );

      if (result is AresFailure<List<CodeArtifact>>) {
        notes.add('Deneme $attempt: düzeltme üretilemedi.');
        if (attempt == CeoSelfHealService.maxAttempts) {
          return _HealingResult(
            success: false,
            artifacts: current,
            replacedPaths: current.map((a) => a.relativePath).toSet(),
            errors: <String>[result.message, ...report.errors],
            suggestedActions: report.suggestedActions,
            attempts: attempt,
            ceoNotes: notes,
          );
        }
        continue;
      }

      final repaired = (result as AresSuccess<List<CodeArtifact>>).value;
      final merged = _replacePhaseArtifacts(allArtifacts, current, repaired);
      report = _validator.validate(merged);
      if (report.isValid) {
        notes.add('Deneme $attempt: doğrulama başarılı.');
        return _HealingResult(
          success: true,
          artifacts: repaired,
          replacedPaths: current.map((a) => a.relativePath).toSet(),
          errors: const <String>[],
          suggestedActions: const <String>[],
          attempts: attempt,
          ceoNotes: notes,
        );
      }
      current = repaired;
    }

    return _HealingResult(
      success: false,
      artifacts: current,
      replacedPaths: current.map((a) => a.relativePath).toSet(),
      errors: report.errors,
      suggestedActions: report.suggestedActions,
      attempts: CeoSelfHealService.maxAttempts,
      ceoNotes: notes,
    );
  }

  Future<_HealingResult> _selfHealWholeProject({
    required ProjectSpec spec,
    required List<CodeArtifact> artifacts,
    required Future<void> Function(String message) onLog,
  }) async {
    var current = List<CodeArtifact>.from(artifacts);
    var report = _validator.validate(current);
    if (report.isValid) {
      return const _HealingResult(
        success: true,
        artifacts: <CodeArtifact>[],
        replacedPaths: <String>{},
        errors: <String>[],
        suggestedActions: <String>[],
        attempts: 0,
        ceoNotes: <String>[],
      );
    }

    final notes = <String>[];
    final seenSignatures = <String>{};
    for (var attempt = 1; attempt <= CeoSelfHealService.maxAttempts; attempt++) {
      final signature = report.errors.join('|');
      if (!seenSignatures.add(signature)) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: const <String>{},
          errors: const <String>['Aynı proje hatası tekrarlandı; CEO denemeyi durdurdu.'],
          suggestedActions: report.suggestedActions,
          attempts: attempt - 1,
          ceoNotes: notes,
        );
      }

      final affected = _affectedArtifacts(current, report.errors);
      if (affected.isEmpty) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: const <String>{},
          errors: report.errors,
          suggestedActions: report.suggestedActions,
          attempts: attempt,
          ceoNotes: notes,
        );
      }

      final diagnosis = ceoSelfHealService.diagnose(report);
      notes.add('Proje deneme $attempt: $diagnosis');
      await onLog('CEO: $diagnosis');
      var changed = false;
      for (final artifact in affected) {
        final role = _roleFromGeneratedBy(artifact.generatedBy);
        final result = await ceoSelfHealService.repair(
          spec: spec,
          role: role,
          artifacts: <CodeArtifact>[artifact],
          report: report,
        );
        if (result is AresSuccess<List<CodeArtifact>> && result.value.isNotEmpty) {
          current = _replaceArtifacts(current, artifact.relativePath, result.value);
          changed = true;
        }
      }

      if (!changed) {
        notes.add('Proje deneme $attempt: geçerli bir düzeltme üretilemedi.');
        continue;
      }

      report = _validator.validate(current);
      if (report.isValid) {
        artifacts
          ..clear()
          ..addAll(current);
        notes.add('Proje deneme $attempt: doğrulama başarılı.');
        return _HealingResult(
          success: true,
          artifacts: const <CodeArtifact>[],
          replacedPaths: const <String>{},
          errors: const <String>[],
          suggestedActions: const <String>[],
          attempts: attempt,
          ceoNotes: notes,
        );
      }
    }

    return _HealingResult(
      success: false,
      artifacts: current,
      replacedPaths: const <String>{},
      errors: report.errors,
      suggestedActions: report.suggestedActions,
      attempts: CeoSelfHealService.maxAttempts,
      ceoNotes: notes,
    );
  }

  Future<AresResult<List<CodeArtifact>>> _repairArtifact(
    CodegenAgentRole role,
    ProjectSpec spec,
    CodeArtifact artifact,
    CodeValidationReport report,
  ) async {
    final prompt = _buildRepairPrompt(role, spec, <CodeArtifact>[artifact], report);
    try {
      return await _llmCodeGenerator.generate(
        prompt,
        costClass: aiCostClass,
        provider: provider,
        model: model,
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('Self-healing çağrısı başarısız: $error');
    }
  }

  CodegenPrompt _buildRepairPrompt(
    CodegenAgentRole role,
    ProjectSpec spec,
    List<CodeArtifact> artifacts,
    CodeValidationReport report,
  ) {
    final context = artifacts.map((artifact) => '''PATH: ${artifact.relativePath}
GENERATED_BY: ${artifact.generatedBy}
TYPE: ${artifact.type.name}
CONTENT:
${artifact.content}''').join('\n\n');

    return CodegenPrompt(
      role: role,
      systemPrompt: '''Sen DEST-OS ARES Kod Üretim Motorunda çalışan ${role.displayName} ajanısın.
Yalnızca verilen artifact doğrulama hatalarını düzelt.
Çıktı yalnızca geçerli JSON olmalı:
{"artifacts":[{"relativePath":"...","content":"...","type":"dart|yaml|markdown|json|other","generatedBy":"${role.displayName}"}]}
''',
      userPrompt: '''PROJECT_SPEC
projectName: ${spec.projectName}
description: ${spec.description}
packageName: ${spec.packageName}
architecture: ${spec.architecture.name}
features: ${spec.features.join(', ')}
screens: ${spec.screens.join(', ')}

VALIDATION_ERRORS
- ${report.errors.join('\n- ')}

SUGGESTED_ACTIONS
- ${report.suggestedActions.join('\n- ')}

ARTIFACTS_TO_REPAIR
$context

Yalnızca düzeltilmiş artifact JSON'unu döndür.''',
    );
  }

  List<CodeArtifact> _replacePhaseArtifacts(
    List<CodeArtifact> all,
    List<CodeArtifact> oldPhase,
    List<CodeArtifact> repaired,
  ) {
    final oldPaths = oldPhase.map((artifact) => artifact.relativePath).toSet();
    return <CodeArtifact>[...
      all.where((artifact) => !oldPaths.contains(artifact.relativePath)),
      ...repaired,
    ];
  }

  List<CodeArtifact> _replaceArtifacts(
    List<CodeArtifact> source,
    String replacedPath,
    List<CodeArtifact> replacements,
  ) {
    final replacementByPath = <String, CodeArtifact>{
      for (final artifact in replacements) artifact.relativePath: artifact,
    };
    final result = <CodeArtifact>[];
    for (final artifact in source) {
      if (artifact.relativePath == replacedPath) {
        final replacement = replacementByPath[replacedPath];
        if (replacement != null) result.add(replacement);
      } else {
        result.add(artifact);
      }
    }
    for (final replacement in replacements) {
      if (!source.any((artifact) => artifact.relativePath == replacement.relativePath)) {
        result.add(replacement);
      }
    }
    return result;
  }

  List<CodeArtifact> _affectedArtifacts(List<CodeArtifact> artifacts, List<String> errors) {
    return artifacts.where((artifact) => errors.any((error) => error.contains(artifact.relativePath))).toList();
  }

  CodegenAgentRole _roleFromGeneratedBy(String generatedBy) {
    switch (generatedBy.toLowerCase()) {
      case 'productmanager':
      case 'product manager':
        return CodegenAgentRole.productManager;
      case 'architect':
        return CodegenAgentRole.architect;
      case 'qaengineer':
      case 'qa engineer':
        return CodegenAgentRole.qaEngineer;
      case 'devops':
        return CodegenAgentRole.devOps;
      default:
        return CodegenAgentRole.flutterDeveloper;
    }
  }

  String? _validatePhaseOwnership(
    _GenerationPhase phase,
    List<CodeArtifact> generated,
  ) {
    for (final artifact in generated) {
      if (!artifact.relativePath.startsWith(phase.directory)) {
        return '${phase.name} ajanı yetkisi dışındaki dosyayı üretmeye çalıştı: ${artifact.relativePath}';
      }
    }
    final paths = generated.map((artifact) => artifact.relativePath).toList();
    if (paths.toSet().length != paths.length) {
      return '${phase.name} aynı dosya yolunu birden fazla artifact ile üretti.';
    }
    return null;
  }

  /// Önceki ajanların ürettiği dosyalardan, token tasarrufu için kısaltılmış
  /// alıntılar verir. Böylece her ajan öncekinin gerçek çıktısını görür.
  Map<String, String> _previousOutputExcerpts(List<CodeArtifact> artifacts, String directory) {
    const perFileLimit = 1200;
    const totalLimit = 6000;
    final candidates = artifacts
        .where((artifact) => !artifact.relativePath.startsWith(directory))
        .toList()
      ..sort((a, b) {
        final aDoc = a.relativePath.startsWith('docs/') ? 0 : 1;
        final bDoc = b.relativePath.startsWith('docs/') ? 0 : 1;
        if (aDoc != bDoc) return aDoc.compareTo(bDoc);
        return a.relativePath.compareTo(b.relativePath);
      });
    final excerpts = <String, String>{};
    var used = 0;
    for (final artifact in candidates) {
      if (used >= totalLimit) break;
      final room = totalLimit - used;
      final limit = room < perFileLimit ? room : perFileLimit;
      final text = artifact.content.length > limit
          ? '${artifact.content.substring(0, limit)}\n...(kisaltildi)'
          : artifact.content;
      excerpts[artifact.relativePath] = text;
      used += text.length;
    }
    return Map<String, String>.unmodifiable(excerpts);
  }

  List<String> _relevantFiles(List<CodeArtifact> artifacts, String directory) {
    final paths = artifacts
        .where((artifact) =>
            (directory.startsWith('docs/') && artifact.relativePath.startsWith('docs/')) ||
            artifact.relativePath.startsWith(directory))
        .map((artifact) => artifact.relativePath)
        .toSet()
        .toList()
      ..sort();
    return List.unmodifiable(paths);
  }

  GenerationResult _result({
    required bool success,
    required List<CodeArtifact> artifacts,
    required List<String> errors,
    required List<String> suggestions,
    required List<String> logs,
    required int retryCount,
    required int selfHealingCount,
    required DateTime startedAt,
    List<String> ceoNotes = const <String>[],
    Map<String, Object?> extraMetrics = const <String, Object?>{},
  }) {
    return GenerationResult(
      success: success,
      artifacts: artifacts,
      errors: errors,
      suggestedActions: suggestions.toSet().toList(),
      attemptCount: 1 + retryCount + selfHealingCount,
      ceoNotes: ceoNotes,
      metrics: <String, Object?>{
        'artifactCount': artifacts.length,
        'errorCount': errors.length,
        'retryCount': retryCount,
        'selfHealingCount': selfHealingCount,
        'attemptCount': 1 + retryCount + selfHealingCount,
        'ceoNotes': List.unmodifiable(ceoNotes),
        'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
        'logCount': logs.length,
        'logs': List.unmodifiable(logs),
        ...extraMetrics,
      },
    );
  }

  Future<void> _publish({
    required EventType type,
    required String message,
    required String projectName,
  }) async {
    final bus = eventBus;
    if (bus == null) return;
    try {
      await bus.publish(
        EventEnvelope(
          id: 'codegen-${DateTime.now().microsecondsSinceEpoch}',
          type: type,
          createdAt: DateTime.now(),
          source: 'CodeGenerationOrchestrator',
          payload: <String, Object?>{
            'message': message,
            'projectName': projectName,
          },
        ),
      );
    } catch (error) {
      logger?.call('Event Bus bildirimi başarısız: $error');
    }
  }
}

class _GenerationPhase {
  const _GenerationPhase({
    required this.name,
    required this.role,
    required this.directory,
  });

  final String name;
  final CodegenAgentRole role;
  final String directory;
}

class _PhaseResult {
  const _PhaseResult({required this.result, required this.retries});

  final AresResult<List<CodeArtifact>> result;
  final int retries;
}

class _HealingResult {
  const _HealingResult({
    required this.success,
    required this.artifacts,
    required this.replacedPaths,
    required this.errors,
    required this.suggestedActions,
    required this.attempts,
    this.ceoNotes = const <String>[],
  });

  final bool success;
  final List<CodeArtifact> artifacts;
  final Set<String> replacedPaths;
  final List<String> errors;
  final List<String> suggestedActions;
  final int attempts;
  final List<String> ceoNotes;
}
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
      return ContentGenerationResult(
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

## `lib/domain/codegen/project_spec.dart`

```dart
import 'architecture_type.dart';

/// Kod üretim motorunun üreteceği projenin değişmez tanımıdır.
class ProjectSpec {
  /// Creates an immutable project specification.
  ProjectSpec({
    required this.projectName,
    required this.description,
    required this.packageName,
    required this.features,
    required this.architecture,
    required this.requiredPackages,
    required this.screens,
    required this.acceptanceCriteria,
    required this.includeTests,
    required this.includeReadme,
  }) : features = List.unmodifiable(features),
       requiredPackages = List.unmodifiable(requiredPackages),
       screens = List.unmodifiable(screens),
       acceptanceCriteria = List.unmodifiable(acceptanceCriteria);

  /// Display name of the project.
  final String projectName;

  /// High-level description of the requested project.
  final String description;

  /// Dart/Flutter package name.
  final String packageName;

  /// Requested product capabilities.
  final List<String> features;

  /// Architecture strategy to use.
  final ArchitectureType architecture;

  /// Additional packages required by the generated project.
  final List<String> requiredPackages;

  /// Requested screens or presentation surfaces.
  final List<String> screens;

  /// Conditions used to judge whether generation is complete.
  final List<String> acceptanceCriteria;

  /// Whether tests should be included in the generated project.
  final bool includeTests;

  /// Whether project documentation should be included.
  final bool includeReadme;

  /// Returns a copy with the supplied fields replaced.
  ProjectSpec copyWith({
    String? projectName,
    String? description,
    String? packageName,
    List<String>? features,
    ArchitectureType? architecture,
    List<String>? requiredPackages,
    List<String>? screens,
    List<String>? acceptanceCriteria,
    bool? includeTests,
    bool? includeReadme,
  }) {
    return ProjectSpec(
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      packageName: packageName ?? this.packageName,
      features: features ?? this.features,
      architecture: architecture ?? this.architecture,
      requiredPackages: requiredPackages ?? this.requiredPackages,
      screens: screens ?? this.screens,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      includeTests: includeTests ?? this.includeTests,
      includeReadme: includeReadme ?? this.includeReadme,
    );
  }
}
```

## `lib/domain/codegen/generation_plan.dart`

```dart
/// Kod üretim sürecinin değişmez planını temsil eder.
class GenerationPlan {
  /// Creates a generation plan with an immutable step list.
  GenerationPlan({
    required this.projectName,
    required List<GenerationStep> steps,
  }) : steps = List.unmodifiable(steps);

  /// Name of the project being generated.
  final String projectName;

  /// Ordered steps that make up the generation process.
  final List<GenerationStep> steps;

  /// Returns a copy with the supplied fields replaced.
  GenerationPlan copyWith({
    String? projectName,
    List<GenerationStep>? steps,
  }) {
    return GenerationPlan(
      projectName: projectName ?? this.projectName,
      steps: steps ?? this.steps,
    );
  }
}

/// Kod üretim planındaki tek bir adımı temsil eder.
class GenerationStep {
  /// Creates an immutable generation step.
  const GenerationStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.required,
  });

  /// Stable identifier of the step.
  final String id;

  /// Human-readable step name.
  final String name;

  /// Short explanation of what the step does.
  final String description;

  /// Position of the step in the plan.
  final int order;

  /// Whether the step is mandatory for a successful generation.
  final bool required;

  /// Returns a copy with the supplied fields replaced.
  GenerationStep copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? required,
  }) {
    return GenerationStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      required: required ?? this.required,
    );
  }
}
```

## `lib/domain/codegen/generation_result.dart`

```dart
import 'code_artifact.dart';

/// Kod üretim işleminin değişmez sonucudur.
class GenerationResult {
  GenerationResult({
    required this.success,
    required List<CodeArtifact> artifacts,
    required List<String> errors,
    required Map<String, Object?> metrics,
    List<String> suggestedActions = const <String>[],
    this.attemptCount = 1,
    List<String> ceoNotes = const <String>[],
  })  : artifacts = List.unmodifiable(artifacts),
        errors = List.unmodifiable(errors),
        metrics = Map.unmodifiable(metrics),
        suggestedActions = List.unmodifiable(suggestedActions),
        ceoNotes = List.unmodifiable(ceoNotes);

  final bool success;
  final List<CodeArtifact> artifacts;
  final List<String> errors;
  final List<String> suggestedActions;
  final Map<String, Object?> metrics;
  final int attemptCount;
  final List<String> ceoNotes;

  GenerationResult copyWith({
    bool? success,
    List<CodeArtifact>? artifacts,
    List<String>? errors,
    List<String>? suggestedActions,
    Map<String, Object?>? metrics,
    int? attemptCount,
    List<String>? ceoNotes,
  }) {
    return GenerationResult(
      success: success ?? this.success,
      artifacts: artifacts ?? this.artifacts,
      errors: errors ?? this.errors,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      metrics: metrics ?? this.metrics,
      attemptCount: attemptCount ?? this.attemptCount,
      ceoNotes: ceoNotes ?? this.ceoNotes,
    );
  }
}
```

## `lib/domain/content/content_generation_result.dart`

```dart
import '../codegen/code_artifact.dart';

/// Video veya genel içerik üretim işleminin sonucudur.
class ContentGenerationResult {
  /// Creates an immutable content-generation result.
  ContentGenerationResult({
    required this.success,
    required List<CodeArtifact> artifacts,
    required List<String> errors,
    required List<String> suggestedActions,
    required Map<String, Object?> metrics,
  })  : artifacts = List.unmodifiable(artifacts),
        errors = List.unmodifiable(errors),
        suggestedActions = List.unmodifiable(suggestedActions),
        metrics = Map.unmodifiable(metrics);

  /// Whether the requested package passed the quality gate.
  final bool success;
  /// Files generated for the requested content package.
  final List<CodeArtifact> artifacts;
  /// Errors encountered during generation.
  final List<String> errors;
  /// Actions the user can take to resolve failures.
  final List<String> suggestedActions;
  /// Diagnostic metrics.
  final Map<String, Object?> metrics;
}
```

## `lib/application/persistence/persistent_repository.dart`

```dart
import '../../domain/database/entity_record.dart';
import '../database/database_manager.dart';

class PersistentRepository {
  PersistentRepository(this._database);

  final DatabaseManager _database;

  Future<void> save(EntityRecord record) async {
    final transaction = await _database.database.beginTransaction();

    try {
      final existing = await transaction.find(
        record.entityType,
        record.id,
      );

      if (existing == null) {
        await transaction.insert(record);
      } else {
        await transaction.update(record);
      }

      await transaction.commit();
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }

  Future<EntityRecord?> getById(
    String entityType,
    String id,
  ) {
    return _database.database.find(entityType, id);
  }

  Future<List<EntityRecord>> getAll(String entityType) {
    return _database.database.findAll(entityType);
  }

  Future<void> delete(String entityType, String id) async {
    final transaction = await _database.database.beginTransaction();

    try {
      await transaction.delete(entityType, id);
      await transaction.commit();
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }
}
```

## `lib/presentation/security/security_center_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../../application/security/secure_credential_store.dart';
import '../../application/security/security_screen_model.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key, this.model = const SecurityScreenModel(), this.credentialStore});

  final SecurityScreenModel model;
  final SecureCredentialStore? credentialStore;

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  late Future<bool> _keyStatus;

  @override
  void initState() {
    super.initState();
    _keyStatus = _readKeyStatus();
  }

  Future<bool> _readKeyStatus() async {
    final store = widget.credentialStore ?? FlutterSecureCredentialStore();
    final value = await store.readApiKey(providerId: 'free_remote');
    return value != null && value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: Text(widget.model.title),
        backgroundColor: const Color(0xFF08131D),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SecurityCard(
            title: 'Ücretli AI kapısı',
            value: 'Kapalı • açık onay olmadan çalışmaz',
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          FutureBuilder<bool>(
            future: _keyStatus,
            builder: (context, snapshot) {
              final text = snapshot.hasError
                  ? 'Kontrol edilemedi'
                  : snapshot.connectionState != ConnectionState.done
                      ? 'Kontrol ediliyor…'
                      : snapshot.data == true
                          ? 'Evet • güvenli depoda'
                          : 'Hayır • kayıtlı değil';
              return _SecurityCard(
                title: 'API anahtarı',
                value: text,
                icon: snapshot.data == true ? Icons.lock : Icons.lock_outline,
              );
            },
          ),
          const SizedBox(height: 12),
          const _SecurityCard(
            title: 'Dosya yolu koruması',
            value: 'Korumalı • izin verilen çıktı alanı dışına yazılmaz',
            icon: Icons.folder_outlined,
          ),
          const SizedBox(height: 12),
          const _SecurityCard(
            title: 'Güvenlik özeti',
            value: 'İzinsiz dış işlem ve otomatik ücretli AI kullanımı engellenir.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 12),
          _SecurityCard(
            title: 'Kayıtlı güvenlik olayları',
            value: '${widget.model.blockedActions} engellenen işlem • ${widget.model.pendingApprovals} bekleyen onay',
            icon: Icons.fact_check_outlined,
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF0A1722),
        child: ListTile(
          leading: Icon(icon, color: Colors.cyanAccent),
          title: Text(title, style: const TextStyle(color: Colors.white70)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(value, style: const TextStyle(color: Colors.white, height: 1.3)),
          ),
        ),
      );
}
```

## `test/application/codegen/code_generation_orchestrator_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/codegen/code_generation_orchestrator.dart';
import 'package:dest_os_ares/application/codegen/code_validator_service.dart';
import 'package:dest_os_ares/application/codegen/code_writer_service.dart';
import 'package:dest_os_ares/application/codegen/project_scaffold_service.dart';
import 'package:dest_os_ares/application/codegen/project_spec_from_request.dart';
import 'package:dest_os_ares/application/codegen/prompt_builder_service.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/codegen/architecture_type.dart';
import 'package:dest_os_ares/domain/codegen/project_spec.dart';
import 'package:dest_os_ares/infrastructure/codegen/file_system_writer.dart';
import 'package:dest_os_ares/infrastructure/codegen/llm_code_generator.dart';

void main() {
  test('MockLlmCodeGenerator ile Counter uygulaması başarıyla üretilir', () async {
    final root = await Directory.systemTemp.createTemp('ares_codegen_counter_');
    addTearDown(() => root.delete(recursive: true));

    final orchestrator = _orchestrator(
      root,
      MockLlmCodeGenerator(
        responseBuilder: (prompt) {
          switch (prompt.role) {
            case CodegenAgentRole.productManager:
              return _jsonArtifact('docs/product/PRODUCT_SPEC.md', '# Product Spec\n', 'ProductManager', 'markdown');
            case CodegenAgentRole.architect:
              return _jsonArtifact('docs/architecture/ARCHITECTURE.md', '# Architecture\n', 'Architect', 'markdown');
            case CodegenAgentRole.flutterDeveloper:
              if (prompt.userPrompt.contains('lib/domain/.gitkeep')) {
                return _jsonArtifact('lib/domain/counter_model.dart', 'class CounterModel { const CounterModel(this.value); final int value; }\n', 'FlutterDeveloper');
              }
              if (prompt.userPrompt.contains('lib/application/.gitkeep')) {
                return _jsonArtifact('lib/application/counter_service.dart', 'class CounterService { int increment(int value) => value + 1; }\n', 'FlutterDeveloper');
              }
              return _jsonArtifact('lib/presentation/counter_screen.dart', 'class CounterScreen { const CounterScreen(); }\n', 'FlutterDeveloper');
            case CodegenAgentRole.qaEngineer:
              return _jsonArtifact('test/generated/counter_smoke_test.dart', 'void main() {}\n', 'QAEngineer');
            case CodegenAgentRole.devOps:
              return _jsonArtifact('docs/release/BUILD.md', '# Build\n\nflutter build apk --release\n', 'DevOps', 'markdown');
          }
        },
      ),
    );

    final result = await orchestrator.generate(_counterSpec());

    expect(result.success, isTrue);
    expect(result.errors, isEmpty);
    final paths = result.artifacts.map((a) => a.relativePath).toSet();
    expect(paths, containsAll(<String>[
      'lib/main.dart',
      'lib/app/app.dart',
      'lib/domain/counter_model.dart',
      'lib/application/counter_service.dart',
      'lib/presentation/counter_screen.dart',
      'pubspec.yaml',
      'analysis_options.yaml',
    ]));
    expect(await File('${root.path}/lib/main.dart').exists(), isTrue);
    expect(await File('${root.path}/pubspec.yaml').exists(), isTrue);
    expect(result.metrics['retryCount'], 0);
  });

  test('bozuk artifact self-healing ile düzeltilir', () async {
    final root = await Directory.systemTemp.createTemp('ares_codegen_healing_');
    addTearDown(() => root.delete(recursive: true));

    final orchestrator = _orchestrator(
      root,
      MockLlmCodeGenerator(
        responseBuilder: (prompt) {
          final isRepair = prompt.systemPrompt.contains('doğrulama hatalarını');
          if (isRepair) {
            return _jsonArtifact('lib/application/broken_service.dart', 'class BrokenService { const BrokenService(); }\n', 'FlutterDeveloper');
          }
          switch (prompt.role) {
            case CodegenAgentRole.productManager:
              return _jsonArtifact('docs/product/PRODUCT_SPEC.md', '# Product\n', 'ProductManager', 'markdown');
            case CodegenAgentRole.architect:
              return _jsonArtifact('docs/architecture/ARCHITECTURE.md', '# Architecture\n', 'Architect', 'markdown');
            case CodegenAgentRole.flutterDeveloper:
              if (prompt.userPrompt.contains('lib/domain/.gitkeep')) {
                return _jsonArtifact('lib/domain/model.dart', 'class Model { const Model(); }\n', 'FlutterDeveloper');
              }
              if (prompt.userPrompt.contains('lib/application/.gitkeep')) {
                return _jsonArtifact('lib/application/broken_service.dart', 'class BrokenService {\n', 'FlutterDeveloper');
              }
              return _jsonArtifact('lib/presentation/home_screen.dart', 'class HomeScreen { const HomeScreen(); }\n', 'FlutterDeveloper');
            case CodegenAgentRole.qaEngineer:
              return _jsonArtifact('test/generated/smoke_test.dart', 'void main() {}\n', 'QAEngineer');
            case CodegenAgentRole.devOps:
              return _jsonArtifact('docs/release/BUILD.md', '# Build\n', 'DevOps', 'markdown');
          }
        },
      ),
    );

    final result = await orchestrator.generate(_counterSpec());

    expect(result.success, isTrue);
    expect(result.errors, isEmpty);
    expect(result.metrics['selfHealingCount'], greaterThanOrEqualTo(1));
    final repaired = result.artifacts.firstWhere(
      (a) => a.relativePath == 'lib/application/broken_service.dart',
    );
    expect(repaired.content, contains('BrokenService();'));
  });

  test('yüksek seviye istek tutarlı ProjectSpec üretir', () {
    const request = 'Kişisel finans takip APK\'sı hazırla';
    final spec = const ProjectSpecFromRequest().build(request);

    expect(spec.projectName, isNotEmpty);
    expect(spec.description, request);
    expect(spec.packageName, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
    expect(spec.architecture, ArchitectureType.clean);
    expect(spec.features, contains('Gelir ve gider kayıtları'));
    expect(spec.screens, contains('Finans Özeti'));
    expect(spec.requiredPackages, contains('intl'));
    expect(spec.acceptanceCriteria, contains('main.dart ve pubspec.yaml oluşturulmalı'));
    expect(spec.includeTests, isTrue);
    expect(spec.includeReadme, isTrue);
  });

  test('çok kısa istek net hata verir', () {
    expect(
      () => const ProjectSpecFromRequest().build('app'),
      throwsA(isA<ArgumentError>()),
    );
  });
}

CodeGenerationOrchestrator _orchestrator(
  Directory root,
  MockLlmCodeGenerator generator,
) {
  return CodeGenerationOrchestrator(
    scaffoldService: const ProjectScaffoldService(),
    promptBuilder: const PromptBuilderService(),
    llmCodeGenerator: generator,
    codeWriter: CodeWriterService(writer: FileSystemWriter(rootDirectory: root)),
    validator: const CodeValidatorService(),
    aiCostClass: AiCostClass.local,
  );
}

ProjectSpec _counterSpec() => ProjectSpec(
      projectName: 'Counter ARES Test',
      description: 'Basit bir Counter uygulaması üret',
      packageName: 'counter_ares_test',
      features: <String>['Sayaç artırma'],
      architecture: ArchitectureType.clean,
      requiredPackages: <String>[],
      screens: <String>['Counter'],
      acceptanceCriteria: <String>[
        'main.dart ve pubspec.yaml oluşturulmalı',
        'Derlenebilir bir Flutter proje iskeleti oluşturulmalı',
        'Temel ekran oluşturulmalı',
      ],
      includeTests: true,
      includeReadme: true,
    );

String _jsonArtifact(
  String path,
  String content,
  String generatedBy, [
  String type = 'dart',
]) => jsonEncode(<String, Object?>{
      'artifacts': <Map<String, Object?>>[
        <String, Object?>{
          'relativePath': path,
          'content': content,
          'type': type,
          'generatedBy': generatedBy,
        },
      ],
    });
```

## `test/application/codegen/previous_output_context_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/codegen/prompt_builder_service.dart';
import 'package:dest_os_ares/domain/codegen/project_spec.dart';

void main() {
  test('ajan promptu önceki ajanların dosya içeriğini taşır', () {
    final prompt = const PromptBuilderService().build(
      role: CodegenAgentRole.flutterDeveloper,
      projectSpec: ProjectSpec(
        projectName: 'Test',
        description: 'Test uygulaması üret',
        packageName: 'test_app',
        features: <String>['Test'],
        architecture: ArchitectureType.clean,
        requiredPackages: <String>[],
        screens: <String>['Ana'],
        acceptanceCriteria: <String>['main.dart oluşturulmalı'],
        includeTests: true,
        includeReadme: true,
      ),
      relevantFiles: const <String>[],
      fileExcerpts: const <String, String>{'docs/product.md': 'KABUL KRITERI: gorev eklenebilir'},
    );
    expect(prompt.userPrompt, contains('docs/product.md'));
    expect(prompt.userPrompt, contains('KABUL KRITERI'));
  });
}
```

## `test/application/codegen/ai_gateway_adapter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/ai/ai_request.dart';
import 'package:dest_os_ares/infrastructure/codegen/fallback_llm_code_generator.dart';
import 'package:dest_os_ares/infrastructure/codegen/free_remote_ai_gateway_adapter.dart';
import 'package:dest_os_ares/infrastructure/codegen/local_ai_gateway_adapter.dart';
import 'package:dest_os_ares/infrastructure/codegen/llm_code_generator.dart';
import 'package:dest_os_ares/infrastructure/codegen/openai_compatible_transport.dart';
import 'package:dest_os_ares/application/codegen/prompt_builder_service.dart';
import 'package:dest_os_ares/domain/codegen/project_spec.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/domain/codegen/architecture_type.dart';
import 'package:dest_os_ares/core/result/ares_result.dart';
import 'package:dest_os_ares/domain/ai/ai_response.dart';

void main() {
  test('LocalAiGatewayAdapter OpenAI uyumlu cevabı parse eder', () async {
    final adapter = LocalAiGatewayAdapter(
      baseUrl: 'http://localhost:11434',
      model: 'qwen3:4b',
      transport: _FakeTransport((_) async => const AiHttpResponse(
            statusCode: 200,
            body: '{"model":"qwen3:4b","choices":[{"message":{"content":"{\\"artifacts\\":[]}"}}]}',
          )),
    );

    final result = await adapter.generate(
      const AiRequest(instruction: 'test', costClass: AiCostClass.local),
    );

    expect(result, isA<AresSuccess<AiResponse>>());
    expect((result as AresSuccess<AiResponse>).value.text, contains('artifacts'));
  });

  test('FreeRemoteAiGatewayAdapter API key istemciye kodlanmadan header olarak gönderilir', () async {
    final transport = _FakeTransport((request) async {
      expect(request.headers['Authorization'], 'Bearer runtime-key');
      expect(request.uri.toString(), 'https://example.com/v1/chat/completions');
      return const AiHttpResponse(
        statusCode: 200,
        body: '{"model":"free-model","choices":[{"message":{"content":"ok"}}]}',
      );
    });
    final adapter = FreeRemoteAiGatewayAdapter(
      baseUrl: 'https://example.com/v1',
      model: 'free-model',
      apiKey: 'runtime-key',
      transport: transport,
    );

    final result = await adapter.generate(
      const AiRequest(instruction: 'test', costClass: AiCostClass.free),
    );

    expect(result, isA<AresSuccess<AiResponse>>());
  });

  test('FallbackLlmCodeGenerator local başarısız olunca ücretsiz yolu dener', () async {
    final generator = FallbackLlmCodeGenerator(
      local: const _FailingGenerator(),
      free: MockLlmCodeGenerator(
        responseJson: '{"artifacts":[]}',
      ),
    );
    final prompt = PromptBuilderService().build(
      role: CodegenAgentRole.flutterDeveloper,
      projectSpec: ProjectSpec(
        projectName: 'Test',
        description: 'Test uygulaması üret',
        packageName: 'test_app',
        features: <String>['Test'],
        architecture: ArchitectureType.clean,
        requiredPackages: <String>[],
        screens: <String>['Ana'],
        acceptanceCriteria: <String>['main.dart oluşturulmalı'],
        includeTests: true,
        includeReadme: true,
      ),
      relevantFiles: const <String>[],
    );

    final result = await generator.generate(prompt);
    expect(result, isA<AresSuccess<List>>());
  });
}

class _FakeTransport implements AiHttpTransport {
  _FakeTransport(this.handler);

  final Future<AiHttpResponse> Function(_TransportRequest request) handler;

  @override
  Future<AiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 90),
  }) => handler(_TransportRequest(uri: uri, headers: headers, body: body));
}

class _TransportRequest {
  const _TransportRequest({required this.uri, required this.headers, required this.body});
  final Uri uri;
  final Map<String, String> headers;
  final Map<String, Object?> body;
}

class _FailingGenerator implements LlmCodeGenerator {
  const _FailingGenerator();

  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    return const AresFailure<List<CodeArtifact>>('local unavailable');
  }
}
```

## `test/presentation/production_center_modes_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:dest_os_ares/domain/codegen/generation_result.dart';
import 'package:dest_os_ares/domain/content/content_generation_result.dart';
import 'package:dest_os_ares/domain/content/content_mode.dart';
import 'package:dest_os_ares/presentation/home/ares_home_screen.dart';

void main() {
  testWidgets('ana ekran üç üretim modunu görünür sunar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AresHomeScreen(
        onCodeGenerate: (request, {onProgress}) async => GenerationResult(
          success: true, artifacts: [], errors: [], metrics: {},
        ),
        onContentGenerate: ({required mode, required request, duration = '60 saniye', style = 'style', platform = 'platform', contentType = 'type', onProgress}) async => ContentGenerationResult(
          success: true, artifacts: [], errors: [], suggestedActions: [], metrics: {},
        ),
      ),
    ));
    expect(find.text('Mobil Uygulama Üret'), findsOneWidget);
    expect(find.text('Video İçerik Üret'), findsOneWidget);
    expect(find.text('Genel İçerik Üret'), findsOneWidget);
  });

  test('content mode labels are stable', () {
    expect(ContentMode.mobileApp.label, 'Mobil Uygulama Üret');
    expect(ContentMode.video.label, 'Video İçerik Üret');
    expect(ContentMode.general.label, 'Genel İçerik Üret');
  });
}
```

## `test/presentation/live_ui_layout_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/domain/content/content_generation_result.dart';
import 'package:dest_os_ares/domain/content/content_mode.dart';
import 'package:dest_os_ares/domain/codegen/generation_result.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/domain/codegen/artifact_type.dart';
import 'package:dest_os_ares/presentation/codegen/code_generation_screen.dart';
import 'package:dest_os_ares/presentation/content/content_generation_screen.dart';

void main() {
  testWidgets('kod üretimi sırasında eski ÜRET butonu görünmez', (tester) async {
    final future = Future<GenerationResult>.delayed(
      const Duration(milliseconds: 200),
      () => GenerationResult(success: true, artifacts: <CodeArtifact>[], errors: <String>[], metrics: <String, Object?>{}),
    );
    await tester.pumpWidget(MaterialApp(home: CodeGenerationScreen(onGenerate: (_, {onProgress}) => future)));
    await tester.enterText(find.byType(TextField), 'Bir uygulama üret');
    await tester.tap(find.text('ÜRET'));
    await tester.pump();
    expect(find.text('ÜRETİLİYOR...'), findsOneWidget);
    expect(find.text('ÜRET'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('içerik ekranında canlı durum ve sonuç ayrı alanlardadır', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContentGenerationScreen(
          mode: ContentMode.general,
          onGenerate: ({required mode, required request, duration = '', style = '', platform = '', contentType = '', onProgress}) async {
            onProgress?.call('İçerik hazırlanıyor');
            return ContentGenerationResult(
              success: true,
              artifacts: <CodeArtifact>[
                CodeArtifact(relativePath: 'README.md', content: '# test', type: ArtifactType.markdown, generatedBy: 'test'),
              ],
              errors: <String>[],
              suggestedActions: <String>[],
              metrics: <String, Object?>{},
            );
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Bir genel içerik üret');
    await tester.tap(find.text('ÜRET'));
    await tester.pumpAndSettle();
    expect(find.text('CANLI DURUM'), findsOneWidget);
    expect(find.text('SONUÇ'), findsOneWidget);
    expect(find.text('İçerik hazırlanıyor'), findsNothing);
    expect(find.text('Üretim tamamlandı'), findsOneWidget);
  });
}
```

## `test/application/learning/learning_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/learning/in_memory_learning_repository.dart';
import 'package:dest_os_ares/application/learning/learning_service.dart';
import 'package:dest_os_ares/domain/learning/learning_observation.dart';
import 'package:dest_os_ares/domain/learning/learning_source_type.dart';

void main() {
  test('öğrenme gözlemi performans kaydı oluşturur', () async {
    final service = LearningService(repository: InMemoryLearningRepository());
    final record = await service.recordObservation(
      LearningObservation(
        id: 'obs-1',
        sourceType: LearningSourceType.taskOutcome,
        subjectId: 'agent-1',
        score: 0.9,
        success: true,
        summary: 'Görev başarıyla tamamlandı.',
        observedAt: DateTime(2026, 1, 1),
      ),
    );
    expect(record.sampleCount, 1);
    expect(record.successRate, 1);
  });

  test('öğrenme güvenliği ücretli AI değişikliğini engeller', () async {
    final service = LearningService(repository: InMemoryLearningRepository());
    final recommendation = await service.recommendImprovement(
      targetType: 'ai',
      targetId: 'model-1',
      action: 'paid ai etkinleştir',
      confidence: 0.99,
      reason: 'Daha yüksek kalite.',
    );
    expect(recommendation, isNull);
  });
}
```

## `test/application/testing/integration_test_harness_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/testing/integration_test_harness.dart';
import 'package:dest_os_ares/application/testing/production_readiness_service.dart';

void main() {
  test('integration harness records passing checks', () {
    final harness = IntegrationTestHarness();
    final result = harness.runCheck(
      testId: 'security',
      check: () => true,
    );

    expect(result.passed, isTrue);
    expect(harness.allPassed, isTrue);
  });

  test('production readiness reports blockers', () {
    const service = ProductionReadinessService();
    final blockers = service.blockers(
      securityPassed: true,
      paidAiGatePassed: true,
      backupRestorePassed: false,
      migrationPassed: true,
      integrationPassed: true,
    );

    expect(blockers, contains('Yedekleme/geri yükleme kontrolü başarısız.'));
    expect(service.isReady(
      securityPassed: true,
      paidAiGatePassed: true,
      backupRestorePassed: false,
      migrationPassed: true,
      integrationPassed: true,
    ), isFalse);
  });
}
```

