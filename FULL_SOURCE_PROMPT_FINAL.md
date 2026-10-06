# DEST-OS ARES — Prompt Final Tam Kaynak Dosyaları

Bu dosya, son turda eklenen/değiştirilen kaynakların tam içeriklerini içerir.



## `pubspec.yaml`

```text
name: dest_os_ares
description: DEST-OS ARES sanal şirket ve yapay zeka çalışma sistemi.
publish_to: "none"
version: 0.1.0+1

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  path: ^1.9.1
  path_provider: ^2.1.5
  http: ^1.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```


## `lib/main.dart`

```text
import 'package:flutter/material.dart';

import 'app/ares_app.dart';
import 'application/codegen/code_generation_orchestrator.dart';
import 'application/codegen/code_generation_request_service.dart';
import 'application/codegen/code_validator_service.dart';
import 'application/codegen/code_writer_service.dart';
import 'application/codegen/project_scaffold_service.dart';
import 'application/codegen/prompt_builder_service.dart';
import 'application/runtime/production/production_composition_root.dart';
import 'core/security/cost_policy.dart';
import 'infrastructure/codegen/fallback_llm_code_generator.dart';
import 'infrastructure/codegen/file_system_writer.dart';
import 'infrastructure/codegen/free_remote_ai_gateway_adapter.dart';
import 'infrastructure/codegen/llm_code_generator.dart';
import 'infrastructure/codegen/local_ai_gateway_adapter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const localBaseUrl = String.fromEnvironment(
    'ARES_LOCAL_AI_BASE_URL',
    defaultValue: 'http://localhost:11434',
  );
  const localModel = String.fromEnvironment(
    'ARES_LOCAL_AI_MODEL',
    defaultValue: 'qwen3:4b',
  );
  const freeBaseUrl = String.fromEnvironment('ARES_FREE_AI_BASE_URL');
  const freeModel = String.fromEnvironment(
    'ARES_FREE_AI_MODEL',
    defaultValue: '',
  );
  const freeApiKey = String.fromEnvironment('ARES_FREE_AI_API_KEY');
  const freeCostClassName = String.fromEnvironment(
    'ARES_FREE_AI_COST_CLASS',
    defaultValue: 'free',
  );

  final localGenerator = ApiLlmCodeGenerator(
    gateway: LocalAiGatewayAdapter(
      baseUrl: localBaseUrl,
      model: localModel,
    ),
  );

  final freeGenerator = freeBaseUrl.trim().isEmpty
      ? null
      : ApiLlmCodeGenerator(
          gateway: FreeRemoteAiGatewayAdapter(
            baseUrl: freeBaseUrl,
            model: freeModel,
            apiKey: freeApiKey.trim().isEmpty ? null : freeApiKey,
          ),
        );

  final freeCostClass = freeCostClassName == 'limitedFree'
      ? AiCostClass.limitedFree
      : AiCostClass.free;

  final llmGenerator = FallbackLlmCodeGenerator(
    local: localGenerator,
    free: freeGenerator,
    freeCostClass: freeCostClass,
  );

  final orchestrator = CodeGenerationOrchestrator(
    scaffoldService: const ProjectScaffoldService(),
    promptBuilder: const PromptBuilderService(),
    llmCodeGenerator: llmGenerator,
    codeWriter: CodeWriterService(
      writer: FileSystemWriter(),
    ),
    validator: const CodeValidatorService(),
    aiCostClass: AiCostClass.local,
  );

  final compositionRoot = ProductionCompositionRoot(
    codeGenerationOrchestrator: orchestrator,
  );

  final CodeGenerationRequestService requestService =
      compositionRoot.buildCodeGenerationRequestService();

  runApp(
    AresApp(
      onCodeGenerate: (
        request, {
        onProgress,
      }) =>
          requestService.generate(
        request,
        onProgress: onProgress,
      ),
    ),
  );
}
```


## `lib/application/codegen/code_generation_orchestrator.dart`

```text
import '../../application/events/event_bus.dart';
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
  })  : _scaffoldService = scaffoldService,
        _promptBuilder = promptBuilder,
        _llmCodeGenerator = llmCodeGenerator,
        _codeWriter = codeWriter,
        _validator = validator;

  final ProjectScaffoldService _scaffoldService;
  final PromptBuilderService _promptBuilder;
  final LlmCodeGenerator _llmCodeGenerator;
  final CodeWriterService _codeWriter;
  final CodeValidatorService _validator;

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
      writeResult = await _codeWriter.writeArtifacts(
        List.unmodifiable(artifacts),
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
      extraMetrics: <String, Object?>{
        'buildReady': readiness.ready,
        'hasMain': readiness.hasMain,
        'hasPubspec': readiness.hasPubspec,
        'hasScreen': readiness.hasScreen,
        'hasAnalysisOptions': readiness.hasAnalysisOptions,
        'brokenCriticalImportCount': readiness.brokenCriticalImports.length,
      },
    );
  }

  GenerationPlan _createPlan(ProjectSpec spec) {
    return const GenerationPlan(
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

    for (var attempt = 1; attempt <= maxSelfHealingAttempts; attempt++) {
      await onLog('${phase.name}: self-healing ${attempt}/${maxSelfHealingAttempts}.');
      final prompt = _buildRepairPrompt(phase.role, spec, current, report);
      AresResult<List<CodeArtifact>> result;
      try {
        result = await _llmCodeGenerator.generate(
          prompt,
          costClass: aiCostClass,
          provider: provider,
          model: model,
        );
      } catch (error) {
        result = AresFailure<List<CodeArtifact>>(
          'Self-healing LLM çağrısı beklenmeyen bir hata verdi: $error',
        );
      }

      if (result is AresFailure<List<CodeArtifact>>) {
        if (attempt == maxSelfHealingAttempts) {
          return _HealingResult(
            success: false,
            artifacts: current,
            replacedPaths: current.map((a) => a.relativePath).toSet(),
            errors: <String>[result.message, ...report.errors],
            suggestedActions: report.suggestedActions,
            attempts: attempt,
          );
        }
        continue;
      }

      final repaired = (result as AresSuccess<List<CodeArtifact>>).value;
      final merged = _replacePhaseArtifacts(allArtifacts, current, repaired);
      report = _validator.validate(merged);
      if (report.isValid) {
        return _HealingResult(
          success: true,
          artifacts: repaired,
          replacedPaths: current.map((a) => a.relativePath).toSet(),
          errors: const <String>[],
          suggestedActions: const <String>[],
          attempts: attempt,
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
      attempts: maxSelfHealingAttempts,
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
      );
    }

    for (var attempt = 1; attempt <= maxSelfHealingAttempts; attempt++) {
      await onLog('Proje geneli self-healing ${attempt}/${maxSelfHealingAttempts}.');
      final affected = _affectedArtifacts(current, report.errors);
      if (affected.isEmpty) {
        return _HealingResult(
          success: false,
          artifacts: current,
          replacedPaths: const <String>{},
          errors: report.errors,
          suggestedActions: report.suggestedActions,
          attempts: attempt,
        );
      }

      var changed = false;
      for (final artifact in affected) {
        final role = _roleFromGeneratedBy(artifact.generatedBy);
        final result = await _repairArtifact(role, spec, artifact, report);
        if (result is AresSuccess<List<CodeArtifact>> && result.value.isNotEmpty) {
          current = _replaceArtifacts(current, artifact.relativePath, result.value);
          changed = true;
        }
      }

      if (!changed) {
        report = CodeValidationReport(
          errors: <String>['Self-healing hiçbir artifact için geçerli düzeltme üretemedi.'],
          suggestedActions: const <String>['LLM sağlayıcısını ve üretilen JSON artifact biçimini kontrol et.'],
        );
        continue;
      }

      report = _validator.validate(current);
      if (report.isValid) {
        artifacts
          ..clear()
          ..addAll(current);
        return _HealingResult(
          success: true,
          artifacts: const <CodeArtifact>[],
          replacedPaths: const <String>{},
          errors: const <String>[],
          suggestedActions: const <String>[],
          attempts: attempt,
        );
      }
    }

    return _HealingResult(
      success: false,
      artifacts: current,
      replacedPaths: const <String>{},
      errors: report.errors,
      suggestedActions: report.suggestedActions,
      attempts: maxSelfHealingAttempts,
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
    Map<String, Object?> extraMetrics = const <String, Object?>{},
  }) {
    return GenerationResult(
      success: success,
      artifacts: artifacts,
      errors: errors,
      suggestedActions: suggestions.toSet().toList(),
      metrics: <String, Object?>{
        'artifactCount': artifacts.length,
        'errorCount': errors.length,
        'retryCount': retryCount,
        'selfHealingCount': selfHealingCount,
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
  });

  final bool success;
  final List<CodeArtifact> artifacts;
  final Set<String> replacedPaths;
  final List<String> errors;
  final List<String> suggestedActions;
  final int attempts;
}
```


## `lib/application/codegen/build_readiness_service.dart`

```text
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
      '${hasScreen ? '✓' : '✗'} en az bir presentation ekranı',
      '${brokenImports.isEmpty ? '✓' : '✗'} kritik relative importlar',
    ];

    final ready = hasMain && hasPubspec && hasAnalysis && hasScreen && brokenImports.isEmpty;
    return BuildReadinessReport(
      ready: ready,
      hasMain: hasMain,
      hasPubspec: hasPubspec,
      hasScreen: hasScreen,
      hasAnalysisOptions: hasAnalysis,
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


## `lib/application/codegen/project_spec_from_request.dart`

```text
import '../../domain/codegen/architecture_type.dart';
import '../../domain/codegen/project_spec.dart';

/// Converts a high-level user request into a deterministic [ProjectSpec].
///
/// This service never calls an AI provider. It performs local normalization,
/// feature/screen inference and safe package-name generation before the AI
/// agents receive the resulting specification.
class ProjectSpecFromRequest {
  /// Creates the request-to-spec converter.
  const ProjectSpecFromRequest();

  /// Builds a consistent project specification from [request].
  ProjectSpec build(String request) {
    final text = request.trim();
    if (text.length < 5 || text.split(RegExp(r'\s+')).length < 2) {
      throw ArgumentError.value(
        request,
        'request',
        'İstek çok kısa. Üretilecek uygulamayı ve temel amacını açıkça yazın.',
      );
    }

    final lower = text.toLowerCase();
    final projectName = _projectName(text);
    final packageName = _packageName(projectName);
    final features = <String>[];
    final screens = <String>[];
    final packages = <String>[];

    void addFeature(String feature) => _addUnique(features, feature);
    void addScreen(String screen) => _addUnique(screens, screen);
    void addPackage(String packageName) => _addUnique(packages, packageName);

    if (_containsAny(lower, const ['counter', 'sayaç'])) {
      addFeature('Sayaç değerini artırma ve azaltma');
      addScreen('Counter');
    }
    if (_containsAny(lower, const ['görev', 'task', 'todo', 'yapılacak'])) {
      addFeature('Görev ekleme, listeleme ve tamamlanma durumu');
      addScreen('Görevler');
      addPackage('shared_preferences');
    }
    if (_containsAny(lower, const ['finans', 'bütçe', 'harcama', 'gelir', 'gider'])) {
      addFeature('Gelir ve gider kayıtları');
      addFeature('Bakiye ve özet görünümü');
      addScreen('Finans Özeti');
      addScreen('İşlemler');
      addPackage('intl');
      addPackage('shared_preferences');
    }
    if (_containsAny(lower, const ['chat', 'sohbet', 'mesaj', 'mesajlaşma'])) {
      addFeature('Mesaj gönderme ve konuşma geçmişi');
      addScreen('Sohbet');
    }
    if (_containsAny(lower, const ['ayar', 'settings', 'profil'])) {
      addFeature('Uygulama ayarları ve kullanıcı tercihleri');
      addScreen('Ayarlar');
    }
    if (_containsAny(lower, const ['hava', 'weather', 'konum', 'harita', 'map'])) {
      addFeature('Konum veya dış veri gösterimi');
      addScreen('Bilgi / Harita');
      addPackage('http');
    }
    if (_containsAny(lower, const ['giriş', 'login', 'oturum', 'kullanıcı'])) {
      addFeature('Kullanıcı giriş ve oturum akışı');
      addScreen('Giriş');
    }
    if (_containsAny(lower, const ['liste', 'catalog', 'katalog', 'ürün'])) {
      addFeature('Listeleme ve detay görüntüleme');
      addScreen('Liste');
      addScreen('Detay');
    }
    if (_containsAny(lower, const ['not', 'note'])) {
      addFeature('Not oluşturma ve düzenleme');
      addScreen('Notlar');
      addPackage('shared_preferences');
    }

    if (features.isEmpty) {
      addFeature('Kullanıcının yüksek seviyeli isteğinin temel iş akışı');
    }
    if (screens.isEmpty) {
      addScreen('Ana Ekran');
    }

    return ProjectSpec(
      projectName: projectName,
      description: text,
      packageName: packageName,
      features: features,
      architecture: ArchitectureType.clean,
      requiredPackages: packages,
      screens: screens,
      acceptanceCriteria: <String>[
        'main.dart ve pubspec.yaml oluşturulmalı',
        'Derlenebilir bir Flutter proje iskeleti oluşturulmalı',
        'Temel ekran veya ekranlar oluşturulmalı',
        'Domain, application ve presentation katmanlarında tutarlı kod bulunmalı',
        'Kritik importlar ve temel yapı doğrulama kontrolünden geçmeli',
      ],
      includeTests: true,
      includeReadme: true,
    );
  }

  String _projectName(String request) {
    final cleaned = request
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(r'^(basit bir|bir|basit|kişisel)\s+', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'\s+(üret|oluştur|yap|hazırla|geliştir|create|build|make)\.?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    final source = cleaned.isEmpty ? 'Üretilen Uygulama' : cleaned;
    final words = source.split(' ').where((word) => word.isNotEmpty).take(6);
    final title = words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return 'ARES $title';
  }

  String _packageName(String projectName) {
    final value = projectName
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = value.isEmpty ? 'ares_generated_app' : value;
    return RegExp(r'^[0-9]').hasMatch(safe) ? 'ares_generated_app' : safe;
  }

  bool _containsAny(String value, List<String> keywords) =>
      keywords.any(value.contains);

  void _addUnique(List<String> values, String value) {
    if (!values.contains(value)) values.add(value);
  }
}
```


## `lib/application/codegen/prompt_builder_service.dart`

```text
import '../../domain/codegen/project_spec.dart';

/// Kod üretiminde kullanılabilecek ajan rolleri.
enum CodegenAgentRole {
  /// Clarifies the product request and acceptance criteria.
  productManager,

  /// Defines architecture and boundaries.
  architect,

  /// Produces Flutter/Dart implementation code.
  flutterDeveloper,

  /// Focuses on tests and acceptance criteria.
  qaEngineer,

  /// Produces build, CI/CD, and deployment artifacts.
  devOps,
}

extension CodegenAgentRoleLabel on CodegenAgentRole {
  /// Human-readable name used in prompts and artifact metadata.
  String get displayName {
    switch (this) {
      case CodegenAgentRole.productManager:
        return 'ProductManager';
      case CodegenAgentRole.architect:
        return 'Architect';
      case CodegenAgentRole.flutterDeveloper:
        return 'FlutterDeveloper';
      case CodegenAgentRole.qaEngineer:
        return 'QAEngineer';
      case CodegenAgentRole.devOps:
        return 'DevOps';
    }
  }
}

/// LLM'e gönderilecek sistem ve kullanıcı promptlarını birlikte taşır.
class CodegenPrompt {
  /// Creates a structured prompt for a code-generation agent.
  const CodegenPrompt({
    required this.role,
    required this.systemPrompt,
    required this.userPrompt,
  });

  /// Agent role receiving the prompt.
  final CodegenAgentRole role;

  /// System-level instructions for the agent.
  final String systemPrompt;

  /// User-level task and context instructions.
  final String userPrompt;
}

/// Her ajan rolü için güvenli ve sınırlı bağlam oluşturan prompt üreticisidir.
class PromptBuilderService {
  /// Creates a prompt builder.
  const PromptBuilderService();

  /// Builds a role-specific prompt from the project specification and file list.
  CodegenPrompt build({
    required CodegenAgentRole role,
    required ProjectSpec projectSpec,
    required List<String> relevantFiles,
  }) {
    final roleName = role.displayName;
    final context = _buildContext(
      projectSpec: projectSpec,
      relevantFiles: relevantFiles,
    );

    return CodegenPrompt(
      role: role,
      systemPrompt: _systemPrompt(roleName),
      userPrompt: _userPrompt(
        roleName: roleName,
        context: context,
      ),
    );
  }

  String _systemPrompt(String roleName) {
    final common = '''
Sen DEST-OS ARES Kod Üretim Motoru içinde çalışan $roleName ajanısın.
Sadece sana verilen ProjectSpec ve ilgili dosya bağlamını kullan.
Bağlamda bulunmayan proje ayrıntılarını uydurma.
Ürettiğin çıktı JSON olmalı ve şu kök yapıyı kullanmalıdır:
{"artifacts":[{"relativePath":"...","content":"...","type":"dart|yaml|markdown|json|other","generatedBy":"$roleName"}]}
Her artifact gerçek bir dosyayı temsil eder. relativePath göreli olmalı ve proje kökü dışına çıkmamalıdır.
''';

    switch (roleName) {
      case 'ProductManager':
        return '$common\nİsteği netleştir, özellikleri ve kabul kriterlerini doğrula; yalnızca ürün tanımını temsil eden belgeleri üret.';
      case 'Architect':
        return '$common\nMimari sınırları, katman ayrımını, bağımlılık yönünü ve dosya sorumluluklarını koru.';
      case 'FlutterDeveloper':
        return '$common\nFlutter/Dart kodunu derlenebilir, okunabilir ve mevcut mimariye uyumlu üret.';
      case 'QAEngineer':
        return '$common\nTest edilebilirlik, acceptance criteria, hata senaryoları ve doğrulanabilir çıktılara odaklan.';
      case 'DevOps':
        return '$common\nBuild, yapılandırma, CI/CD, ortam ve dağıtım dosyalarını güvenli ve tekrarlanabilir üret.';
      default:
        return common;
    }
  }

  String _userPrompt({
    required String roleName,
    required String context,
  }) {
    return '''
Rol: $roleName

Aşağıdaki sınırlı bağlamı kullanarak görevi yerine getir.
Sadece bu bağlamdaki ProjectSpec ve ilgili dosyalarla ilişkili dosyaları üret.
Mevcut dosyaları değiştirmek gerekiyorsa tam dosya içeriğini artifact olarak döndür.

BAĞLAM:
$context

Çıktı yalnızca geçerli JSON olsun. Açıklama, Markdown çiti veya JSON dışı metin ekleme.
''';
  }

  String _buildContext({
    required ProjectSpec projectSpec,
    required List<String> relevantFiles,
  }) {
    final files = List.unmodifiable(relevantFiles);
    final buffer = StringBuffer()
      ..writeln('PROJECT_SPEC')
      ..writeln('projectName: ${projectSpec.projectName}')
      ..writeln('description: ${projectSpec.description}')
      ..writeln('packageName: ${projectSpec.packageName}')
      ..writeln('architecture: ${projectSpec.architecture.name}')
      ..writeln('features: ${projectSpec.features.join(', ')}')
      ..writeln('requiredPackages: ${projectSpec.requiredPackages.join(', ')}')
      ..writeln('screens: ${projectSpec.screens.join(', ')}')
      ..writeln('acceptanceCriteria: ${projectSpec.acceptanceCriteria.join(' | ')}')
      ..writeln('includeTests: ${projectSpec.includeTests}')
      ..writeln('includeReadme: ${projectSpec.includeReadme}')
      ..writeln()
      ..writeln('RELEVANT_FILES');

    if (files.isEmpty) {
      buffer.writeln('(none)');
    } else {
      for (final file in files) {
        buffer.writeln('- $file');
      }
    }

    return buffer.toString();
  }
}
```


## `lib/application/codegen/code_generation_request_service.dart`

```text
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
```


## `lib/application/codegen/code_generation_runtime_module.dart`

```text
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
```


## `lib/application/codegen/README.md`

```text
# DEST-OS ARES Kod Üretim Motoru

Bu motor yüksek seviyeli bir kullanıcı isteğini güvenli bir Flutter proje iskeletine dönüştürür.

## Uçtan uca akış

1. Ana ekranda **KOD ÜRETİM MERKEZİ** açılır.
2. Kullanıcı örneğin `Basit bir Counter uygulaması üret` yazar.
3. `CodeGenerationRequestService` isteği `ProjectSpecFromRequest` ile `ProjectSpec` haline getirir.
4. `ProductionCompositionRoot` üzerinden `CodeGenerationRuntimeModule` başlatılır.
5. `CodeGenerationOrchestrator` üretim planını yürütür.
6. Product Manager isteği/kabul kriterlerini, System Architect mimariyi, Flutter Developer Dart kodunu, QA Engineer test/kalite çıktısını, DevOps/Release Agent build hazırlık belgelerini üretir.
7. `Validator` temel yapı, import ve pubspec kontrollerini yapar.
8. Hata bulunursa en fazla üç self-healing turu çalışır.
9. `BuildReadinessService` main.dart, pubspec.yaml, analysis_options.yaml, ekran ve kritik importları kontrol eder.
10. `FileSystemWriter` path traversal koruması ile dosyaları güvenli köke yazar.
11. `GenerationResult` UI'ya başarı, hata, dosya, retry ve self-healing bilgilerini taşır.

## Yerel AI: Ollama veya LM Studio

Motor OpenAI-compatible `/v1/chat/completions` endpoint'i kullanır.

Varsayılan Ollama ayarı:

```text
ARES_LOCAL_AI_BASE_URL=http://localhost:11434
ARES_LOCAL_AI_MODEL=qwen3:4b
```

Örnek Flutter çalıştırma:

```text
flutter run --dart-define=ARES_LOCAL_AI_BASE_URL=http://localhost:11434 --dart-define=ARES_LOCAL_AI_MODEL=qwen3:4b
```

LM Studio için örnek:

```text
flutter run --dart-define=ARES_LOCAL_AI_BASE_URL=http://localhost:1234 --dart-define=ARES_LOCAL_AI_MODEL=<yerel-model>
```

Cihaz/emülatör ile bilgisayar arasındaki ağ adresinin doğru olması gerekir. Android emülatörde bilgisayarın localhost adresi çoğu durumda `10.0.2.2` olarak kullanılır.

Yerel model gerçekten kullanılmadan önce cihazda/PC'de modelin kurulu ve ücretsiz lisans şartlarının uygun olduğu doğrulanmalıdır.

## Ücretsiz uzak AI

OpenAI-compatible endpoint sağlayan ücretsiz veya sınırlı ücretsiz bir servis kullanılabilir.

```text
ARES_FREE_AI_BASE_URL=https://<provider>/v1
ARES_FREE_AI_MODEL=<free-model>
ARES_FREE_AI_API_KEY=<runtime-secret>
ARES_FREE_AI_COST_CLASS=free  # veya limitedFree
```

API anahtarı kaynak koda yazılmaz. `--dart-define` veya uygulamanın güvenli credential/config mekanizması üzerinden çalışma zamanına aktarılmalıdır.

Örnek:

```text
flutter run \
  --dart-define=ARES_LOCAL_AI_BASE_URL=http://localhost:11434 \
  --dart-define=ARES_FREE_AI_BASE_URL=https://<provider>/v1 \
  --dart-define=ARES_FREE_AI_MODEL=<free-model> \
  --dart-define=ARES_FREE_AI_API_KEY=<runtime-secret>
ARES_FREE_AI_COST_CLASS=free  # veya limitedFree
```

## Fallback sırası

```text
Yerel AI
   ↓ başarısızsa
Ücretsiz / sınırlı ücretsiz uzak AI
   ↓ o da başarısızsa
Net hata + kurulum/yapılandırma mesajı
```

Mock AI üretim uygulamasında kullanılmaz; yalnızca testlerde kullanılır.

## Maliyet güvenliği

`PaidAiRuntimeGate` ve `DecisionEngine` korunur.

- `local`: onaysız çalışabilir.
- `free`: onaysız çalışabilir.
- `limitedFree`: onaysız çalışabilir fakat limitler kontrol edilmelidir.
- `paid`: İbrahim'in açık onayı gerekir.
- `unknown`: ücretsiz kabul edilmez ve onay olmadan çalıştırılmaz.

Hiçbir adapter Paid Gate'i bypass etmez.

## Ajan sorumlulukları

| Ajan | Sorumluluk | Ana çıktı |
|---|---|---|
| Product Manager | İstek ve kabul kriterleri | `docs/product/PRODUCT_SPEC.md` |
| System Architect | Mimari ve sınırlar | `docs/architecture/ARCHITECTURE.md` |
| Flutter Developer | Domain/Application/Presentation | `lib/.../*.dart` |
| QA Engineer | Test ve kalite | `test/generated/...` |
| DevOps / Release | Build ve release hazırlığı | `docs/release/BUILD.md` |

Her fazın çıktısı validator'dan geçer; hata varsa ilgili ajan için retry/self-healing uygulanır. Ajanlar farklı sorumluluk alanlarına ait dosyaları sessizce ezmemelidir.

## İlk başarılı üretim

1. Ollama veya LM Studio'yu kurun.
2. Ücretsiz/lisansı uygun bir yerel model indirin.
3. OpenAI-compatible endpoint'i açın.
4. ARES'i `ARES_LOCAL_AI_BASE_URL` ve `ARES_LOCAL_AI_MODEL` ile başlatın.
5. **KOD ÜRETİM MERKEZİ**ne girin.
6. `Basit bir Counter uygulaması üret` yazın.
7. **ÜRET** düğmesine basın.
8. UI'da Product Manager → Architect → Domain → Application → Presentation → QA → DevOps → Doğrulama → Yazma adımlarını izleyin.
9. Başarı sonunda üretilen dosyalar ve `docs/BUILD_READINESS.md` gösterilir.
10. Flutter bulunan geliştirme ortamında `flutter pub get`, `flutter analyze`, `flutter test` ve `flutter build apk --release` çalıştırılır.

## Flutter olmayan ortam

Bu geliştirme ortamında Flutter SDK yoksa motor yine dosya üretimi ve deterministik doğrulama yapabilir; ancak gerçek `flutter analyze`, `flutter test` ve APK build işlemleri Flutter SDK bulunan geliştirme makinesinde çalıştırılmalıdır. Sistem bu komutları raporlar; çalıştırılmış gibi davranmaz.

## Son kontrol listesi

- [x] Ana ekran → Kod Üretim Merkezi
- [x] `onGenerate` gerçek application facade'a bağlı
- [x] İstek → ProjectSpec
- [x] Local AI adapter
- [x] Free remote AI adapter
- [x] Local → Free fallback
- [x] Mock yalnızca testte
- [x] Orchestrator
- [x] Product Manager
- [x] System Architect
- [x] Flutter Developer
- [x] QA Engineer
- [x] DevOps / Release
- [x] Validator
- [x] Self-healing
- [x] Build readiness report
- [x] Güvenli dosya yazımı
- [x] Paid AI Gate
- [x] API key kaynak kodda değil
- [x] Adapter testleri
- [x] Orchestrator başarı/hata testleri
- [x] ProjectSpec testleri
- [x] UI callback testi
```


## `lib/infrastructure/codegen/openai_compatible_transport.dart`

```text
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
```


## `lib/infrastructure/codegen/local_ai_gateway_adapter.dart`

```text
import 'dart:async';
import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../core/result/ares_result.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import 'openai_compatible_transport.dart';

/// OpenAI-compatible gateway adapter for local Ollama or LM Studio servers.
class LocalAiGatewayAdapter implements AresAiGateway {
  /// Creates a local AI adapter.
  LocalAiGatewayAdapter({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'qwen3:4b',
    AiHttpTransport? transport,
    this.timeout = const Duration(seconds: 90),
  }) : _transport = transport ?? const DartIoAiHttpTransport();

  /// Base URL of Ollama or LM Studio.
  final String baseUrl;

  /// Local model identifier.
  final String model;

  /// Request timeout.
  final Duration timeout;

  final AiHttpTransport _transport;

  /// Calls the local OpenAI-compatible chat endpoint.
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    try {
      final response = await _transport.postJson(
        uri: _chatUri(baseUrl),
        headers: const <String, String>{},
        timeout: timeout,
        body: <String, Object?>{
          'model': model,
          'temperature': 0,
          'messages': <Map<String, String>>[
            <String, String>{'role': 'user', 'content': request.instruction},
          ],
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AresFailure<AiResponse>(
          'Yerel AI HTTP ${response.statusCode}: ${_short(response.body)}',
        );
      }
      final decoded = jsonDecode(response.body);
      final content = _content(decoded);
      if (content == null || content.trim().isEmpty) {
        return const AresFailure<AiResponse>('Yerel AI boş cevap döndürdü.');
      }
      return AresSuccess<AiResponse>(
        AiResponse(
          text: content,
          modelName: decoded is Map && decoded['model'] is String
              ? decoded['model'] as String
              : model,
        ),
      );
    } on TimeoutException {
      return const AresFailure<AiResponse>('Yerel AI zaman aşımına uğradı.');
    } on FormatException catch (error) {
      return AresFailure<AiResponse>('Yerel AI geçersiz JSON döndürdü: ${error.message}');
    } catch (error) {
      return AresFailure<AiResponse>('Yerel AI bağlantısı başarısız: $error');
    }
  }

  Uri _chatUri(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.endsWith('/chat/completions')) return Uri.parse(value);
    if (value.endsWith('/v1')) return Uri.parse('$value/chat/completions');
    return Uri.parse('$value/v1/chat/completions');
  }

  String? _content(dynamic decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) return null;
    final message = choices.first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    if (content is String) return content;
    if (content is List) {
      return content.whereType<Map>().map((part) => part['text']).whereType<String>().join();
    }
    return null;
  }

  String _short(String value) => value.length > 500 ? '${value.substring(0, 500)}…' : value;
}
```


## `lib/infrastructure/codegen/free_remote_ai_gateway_adapter.dart`

```text
import 'dart:async';
import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../core/result/ares_result.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import 'openai_compatible_transport.dart';

/// OpenAI-compatible adapter for a configured free or limited-free remote AI.
class FreeRemoteAiGatewayAdapter implements AresAiGateway {
  /// Creates a remote adapter. Blank [baseUrl] disables this provider.
  FreeRemoteAiGatewayAdapter({
    required this.baseUrl,
    required this.model,
    this.apiKey,
    AiHttpTransport? transport,
    this.timeout = const Duration(seconds: 90),
  }) : _transport = transport ?? const DartIoAiHttpTransport();

  /// Provider base URL.
  final String baseUrl;

  /// Provider model identifier.
  final String model;

  /// Optional runtime API key. It is never stored in source code by this adapter.
  final String? apiKey;

  /// Request timeout.
  final Duration timeout;

  final AiHttpTransport _transport;

  /// Whether enough runtime configuration exists to make a request.
  bool get isConfigured => baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  /// Calls the configured OpenAI-compatible endpoint.
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    if (!isConfigured) {
      return const AresFailure<AiResponse>('Ücretsiz uzak AI yapılandırılmamış.');
    }
    try {
      final headers = <String, String>{};
      final key = apiKey?.trim();
      if (key != null && key.isNotEmpty) {
        headers['Authorization'] = 'Bearer $key';
      }
      final response = await _transport.postJson(
        uri: _chatUri(baseUrl),
        headers: headers,
        timeout: timeout,
        body: <String, Object?>{
          'model': model,
          'temperature': 0,
          'messages': <Map<String, String>>[
            <String, String>{'role': 'user', 'content': request.instruction},
          ],
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AresFailure<AiResponse>(
          'Ücretsiz uzak AI HTTP ${response.statusCode}: ${_short(response.body)}',
        );
      }
      final decoded = jsonDecode(response.body);
      final content = _content(decoded);
      if (content == null || content.trim().isEmpty) {
        return const AresFailure<AiResponse>('Ücretsiz uzak AI boş cevap döndürdü.');
      }
      return AresSuccess<AiResponse>(
        AiResponse(
          text: content,
          modelName: decoded is Map && decoded['model'] is String
              ? decoded['model'] as String
              : model,
        ),
      );
    } on TimeoutException {
      return const AresFailure<AiResponse>('Ücretsiz uzak AI zaman aşımına uğradı.');
    } on FormatException catch (error) {
      return AresFailure<AiResponse>('Ücretsiz uzak AI geçersiz JSON döndürdü: ${error.message}');
    } catch (error) {
      return AresFailure<AiResponse>('Ücretsiz uzak AI bağlantısı başarısız: $error');
    }
  }

  Uri _chatUri(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.endsWith('/chat/completions')) return Uri.parse(value);
    if (value.endsWith('/v1')) return Uri.parse('$value/chat/completions');
    return Uri.parse('$value/v1/chat/completions');
  }

  String? _content(dynamic decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) return null;
    final message = choices.first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  String _short(String value) => value.length > 500 ? '${value.substring(0, 500)}…' : value;
}
```


## `lib/infrastructure/codegen/fallback_llm_code_generator.dart`

```text
import '../../application/codegen/prompt_builder_service.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/codegen/code_artifact.dart';
import 'llm_code_generator.dart';

/// Routes generation from local AI to an explicitly configured free remote AI.
class FallbackLlmCodeGenerator implements LlmCodeGenerator {
  /// Creates a local-first generator with an optional free fallback.
  const FallbackLlmCodeGenerator({required this.local, this.free, this.freeCostClass = AiCostClass.free});

  /// Local generator attempted first.
  final LlmCodeGenerator local;

  /// Free/limited-free generator attempted after local failure.
  final LlmCodeGenerator? free;

  /// Cost classification applied to the remote fallback.
  final AiCostClass freeCostClass;

  /// Tries local first, then free, while each route keeps its own cost gate.
  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    if (costClass == AiCostClass.paid || costClass == AiCostClass.unknown) {
      return const AresFailure<List<CodeArtifact>>(
        'Fallback kod üreticisi ücretli veya bilinmeyen maliyetli AI yolunu otomatik açmaz.',
      );
    }
    final localResult = await local.generate(
      prompt,
      costClass: AiCostClass.local,
      provider: provider,
      model: model,
    );
    if (localResult is AresSuccess<List<CodeArtifact>>) return localResult;

    final freeGenerator = free;
    if (freeGenerator == null) return localResult;

    final freeResult = await freeGenerator.generate(
      prompt,
      costClass: freeCostClass,
      provider: provider,
      model: model,
    );
    if (freeResult is AresSuccess<List<CodeArtifact>>) return freeResult;

    final localMessage = localResult is AresFailure<List<CodeArtifact>>
        ? localResult.message
        : 'Yerel AI başarısız oldu.';
    final freeMessage = freeResult is AresFailure<List<CodeArtifact>>
        ? freeResult.message
        : 'Ücretsiz uzak AI başarısız oldu.';
    return AresFailure<List<CodeArtifact>>(
      'Yerel AI ve ücretsiz uzak AI üretimi başarısız. Yerel: $localMessage Uzak: $freeMessage',
    );
  }
}
```


## `lib/infrastructure/codegen/llm_code_generator.dart`

```text
import 'dart:convert';

import '../../application/ai/ai_gateway.dart';
import '../../application/codegen/prompt_builder_service.dart';
import '../../application/decision/decision_engine.dart';
import '../../application/runtime/paid_ai_runtime_gate.dart';
import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/ai/ai_request.dart';
import '../../domain/ai/ai_response.dart';
import '../../domain/codegen/artifact_type.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/runtime/ai_runtime_request.dart';

/// LLM kod üretimi için altyapı sözleşmesi.
abstract interface class LlmCodeGenerator {
  /// Generates code artifacts for [prompt].
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass,
    String? provider,
    String? model,
  });
}

/// Mevcut ARES AI Gateway üzerinden gerçek API entegrasyonuna hazır üreticidir.
/// Gateway'in kendisi sağlayıcı/API ayrıntılarını yönetir.
class ApiLlmCodeGenerator implements LlmCodeGenerator {
  /// Creates an API-backed code generator using the existing ARES gateway.
  ApiLlmCodeGenerator({
    required this.gateway,
    this.paidGate = const PaidAiRuntimeGate(),
    this.decisionEngine = DecisionEngine(),
  });

  /// Existing ARES AI Gateway used for model requests.
  final AresAiGateway gateway;

  /// Existing gate that blocks paid AI without the required approval.
  final PaidAiRuntimeGate paidGate;

  /// Existing decision engine used before a model request is sent.
  final DecisionEngine decisionEngine;

  /// Sends a structured code-generation request through the existing ARES AI Gateway.
  ///
  /// The [costClass] is evaluated by [paidGate] before the gateway is called.
  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    final runtimeRequest = AiRuntimeRequest(
      instruction: '${prompt.systemPrompt}\n\n${prompt.userPrompt}',
      costClass: costClass,
      provider: provider,
      model: model,
      metadata: <String, Object?>{
        'feature': 'code_generation',
        'agentRole': prompt.role.displayName,
        'structuredOutput': true,
      },
    );

    final gate = paidGate.evaluate(runtimeRequest);
    if (!gate.mayRun) {
      return AresFailure<List<CodeArtifact>>(
        'Kod üretimi başlatılmadı: ${gate.reason}',
      );
    }

    final decision = decisionEngine.decide(
      id: 'codegen-${prompt.role.name}',
      archiveAvailable: false,
      localAiAvailable:
          costClass == AiCostClass.local,
      freeAiAvailable:
          costClass == AiCostClass.free ||
          costClass == AiCostClass.limitedFree,
      paidAiAvailable: costClass == AiCostClass.paid,
    );

    if (decision.requiresUserApproval) {
      return AresFailure<List<CodeArtifact>>(
        'Kod üretimi için İbrahim onayı gerekiyor: ${decision.reason}',
      );
    }

    if (decision.type.name == 'defer') {
      return AresFailure<List<CodeArtifact>>(
        'Kod üretimi ertelendi: ${decision.reason}',
      );
    }

    try {
      final response = await gateway.generate(
        AiRequest(
          instruction: runtimeRequest.instruction,
          costClass: costClass,
        ),
      );

      if (response is AresFailure<AiResponse>) {
        return AresFailure<List<CodeArtifact>>(
          'LLM isteği başarısız: ${response.message}',
        );
      }

      if (response is! AresSuccess<AiResponse>) {
        return const AresFailure<List<CodeArtifact>>(
          'LLM isteği beklenmeyen bir sonuç döndürdü.',
        );
      }

      return _parseStructuredOutput(
        response.value.text,
        fallbackGeneratedBy: prompt.role.displayName,
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>(
        'LLM çağrısı sırasında hata oluştu: $error',
      );
    }
  }

  /// Parses the structured JSON response returned by an LLM.
  AresResult<List<CodeArtifact>> _parseStructuredOutput(
    String raw,
    {required String fallbackGeneratedBy},
  ) {
    try {
      final decoded = jsonDecode(raw);
      final dynamic rawArtifacts = decoded is Map<String, dynamic>
          ? decoded['artifacts']
          : decoded;

      if (rawArtifacts is! List) {
        return const AresFailure<List<CodeArtifact>>(
          'LLM çıktısı geçersiz: "artifacts" listesi bulunamadı.',
        );
      }

      final artifacts = <CodeArtifact>[];
      for (var index = 0; index < rawArtifacts.length; index++) {
        final item = rawArtifacts[index];
        if (item is! Map) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $index numaralı artifact nesne değil.',
          );
        }

        final path = item['relativePath'];
        final content = item['content'];
        final typeValue = item['type'];
        final generatedBy = item['generatedBy'] ?? fallbackGeneratedBy;

        if (path is! String || path.trim().isEmpty) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $index numaralı artifact için relativePath eksik.',
          );
        }
        if (content is! String) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $path için content metin değil.',
          );
        }
        if (generatedBy is! String || generatedBy.trim().isEmpty) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $path için generatedBy eksik.',
          );
        }

        final type = _artifactType(typeValue);
        if (type == null) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı geçersiz: $path için artifact type tanınmıyor.',
          );
        }

        if (_isUnsafeRelativePath(path)) {
          return AresFailure<List<CodeArtifact>>(
            'LLM çıktısı reddedildi: güvenli olmayan dosya yolu "$path".',
          );
        }

        artifacts.add(
          CodeArtifact(
            relativePath: path,
            content: content,
            type: type,
            generatedBy: generatedBy,
          ),
        );
      }

      return AresSuccess<List<CodeArtifact>>(List.unmodifiable(artifacts));
    } on FormatException catch (error) {
      return AresFailure<List<CodeArtifact>>(
        'LLM çıktısı geçerli JSON değil: ${error.message}',
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>(
        'LLM çıktısı CodeArtifact formatına çevrilemedi: $error',
      );
    }
  }

  ArtifactType? _artifactType(Object? value) {
    if (value is! String) {
      return null;
    }

    for (final type in ArtifactType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  bool _isUnsafeRelativePath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return normalized.startsWith('/') ||
        normalized.startsWith('~/') ||
        normalized.split('/').contains('..') ||
        RegExp(r'^[A-Za-z]:/').hasMatch(normalized);
  }
}

/// Gerçek ağ/API çağrısı yapmadan kod üretim akışını test etmek için kullanılır.
class MockLlmCodeGenerator implements LlmCodeGenerator {
  /// Creates a mock generator with an optional fixed JSON response.
  ///
  /// [responseBuilder] can return a different JSON payload for each prompt,
  /// which is useful for multi-phase orchestrator tests.
  const MockLlmCodeGenerator({this.responseJson, this.responseBuilder});

  /// Fixed JSON response returned when [responseBuilder] is not supplied.
  final String? responseJson;

  /// Optional callback used to create a response from the current prompt.
  final String Function(CodegenPrompt prompt)? responseBuilder;

  /// Generates a deterministic mock response without network access.
  /// Generates a deterministic structured response for tests without network access.
  ///
  /// Paid and unknown cost classes remain blocked even in the mock implementation.
  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async {
    if (costClass == AiCostClass.paid || costClass == AiCostClass.unknown) {
      return const AresFailure<List<CodeArtifact>>(
        'Mock kod üreticisi de ücretli/bilinmeyen maliyetli AI kullanımını onaysız çalıştırmaz.',
      );
    }

    final json = responseBuilder?.call(prompt) ?? responseJson ??
        jsonEncode(<String, Object?>{
          'artifacts': <Map<String, Object?>>[
            <String, Object?>{
              'relativePath': 'lib/generated/generated_code.dart',
              'content': '// Mock generated by ARES Codegen.\n',
              'type': 'dart',
              'generatedBy': prompt.role.displayName,
            },
          ],
        });

    final parser = ApiLlmCodeGenerator(
      gateway: _UnusedGateway(),
    );
    return parser._parseStructuredOutput(
      json,
      fallbackGeneratedBy: prompt.role.displayName,
    );
  }
}

class _UnusedGateway implements AresAiGateway {
  @override
  Future<AresResult<AiResponse>> generate(AiRequest request) async {
    return const AresFailure<AiResponse>(
      'Mock parser gerçek ARES AI Gateway çağrısı yapmaz.',
    );
  }
}
```


## `lib/presentation/codegen/code_generation_screen.dart`

```text
import 'package:flutter/material.dart';

import '../../domain/codegen/generation_result.dart';

/// ARES Kod Üretim Motorunun kullanıcı arayüzüdür.
///
/// Presentation katmanı yalnızca dışarıdan verilen [onGenerate] facade'ına
/// bağlıdır. AI Gateway, CEO Brain, Task Engine veya dosya sistemine doğrudan
/// erişmez.
class CodeGenerationScreen extends StatefulWidget {
  /// Creates the code-generation screen.
  const CodeGenerationScreen({super.key, this.onGenerate});

  /// Starts generation for the supplied high-level request.
  final Future<GenerationResult> Function(
    String request, {
    void Function(String status)? onProgress,
  })? onGenerate;

  @override
  State<CodeGenerationScreen> createState() => _CodeGenerationScreenState();
}

class _CodeGenerationScreenState extends State<CodeGenerationScreen> {
  final TextEditingController _requestController = TextEditingController();
  bool _isGenerating = false;
  String _status = 'Hazır';
  int _activeStep = -1;
  GenerationResult? _result;
  String? _errorMessage;

  static const List<String> _steps = <String>[
    'İstek',
    'Plan',
    'Scaffold',
    'Domain',
    'Application',
    'Presentation',
    'Doğrulama',
    'Yazma',
    'Tamam',
  ];

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final request = _requestController.text.trim();
    if (request.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen üretilecek uygulamayı veya projeyi açıklayın.';
        _status = 'İstek bekleniyor';
        _activeStep = 0;
      });
      return;
    }

    final generator = widget.onGenerate;
    if (generator == null) {
      setState(() {
        _errorMessage =
            'Kod üretim çalışma zamanı yapılandırılmamış. Mock AI\'ya sessizce düşülmedi.';
        _status = 'Yapılandırma eksik';
        _activeStep = -1;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'İstek hazırlanıyor';
      _activeStep = 0;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await generator(
        request,
        onProgress: _handleProgress,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isGenerating = false;
        _activeStep = result.success ? _steps.length - 1 : _activeStep;
        _status = result.success
            ? 'Üretim tamamlandı'
            : 'Üretim hatayla tamamlandı';
        _errorMessage = result.success || result.errors.isEmpty
            ? null
            : result.errors.join('\n');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _status = 'Üretim sırasında hata oluştu';
        _errorMessage = '$error';
      });
    }
  }

  void _handleProgress(String status) {
    if (!mounted) return;
    final normalized = status.toLowerCase();
    var step = _activeStep;
    for (var index = 0; index < _steps.length; index++) {
      if (normalized.contains(_steps[index].toLowerCase())) {
        step = index;
        break;
      }
    }
    if (normalized.contains('self-healing')) {
      step = 6;
    }
    setState(() {
      _status = status;
      _activeStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final artifacts = result?.artifacts ?? const [];
    final logs = (result?.metrics['logs'] as List?)?.cast<String>() ?? const <String>[];
    final retryCount = result?.metrics['retryCount'] ?? 0;
    final selfHealingCount = result?.metrics['selfHealingCount'] ?? 0;
    final suggestions = result?.suggestedActions ?? const <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(
        title: const Text('ARES — KOD ÜRETİM MERKEZİ'),
        backgroundColor: const Color(0xFF08131D),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _SectionCard(
              title: 'YÜKSEK SEVİYELİ İSTEK',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _requestController,
                    minLines: 5,
                    maxLines: 9,
                    enabled: !_isGenerating,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Örneğin: Basit bir Counter uygulaması üret.',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF071019),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generate,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'ÜRETİLİYOR...' : 'ÜRET'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF007C91),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'CANLI ÜRETİM DURUMU',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isGenerating
                            ? Icons.sync
                            : result?.success == true
                                ? Icons.check_circle_outline
                                : Icons.memory,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressSteps(activeStep: _activeStep),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (result != null)
              _SectionCard(
                title: 'ÜRETİM METRİKLERİ',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(label: 'Artifact', value: '${result.artifacts.length}'),
                    _MetricChip(label: 'Retry', value: '$retryCount'),
                    _MetricChip(label: 'Self-Healing', value: '$selfHealingCount'),
                    _MetricChip(label: 'Log', value: '${logs.length}'),
                    _MetricChip(
                      label: 'Build Hazır',
                      value: result.metrics['buildReady'] == true ? 'EVET' : 'HAYIR',
                    ),
                  ],
                ),
              ),
            if (result != null) const SizedBox(height: 14),
            _SectionCard(
              title: 'ÜRETİLEN DOSYALAR',
              child: artifacts.isEmpty
                  ? const Text(
                      'Henüz üretilen dosya yok.',
                      style: TextStyle(color: Colors.white54),
                    )
                  : Column(
                      children: artifacts
                          .map(
                            (artifact) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.description_outlined,
                                color: Colors.cyanAccent,
                              ),
                              title: Text(
                                artifact.relativePath,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${artifact.type.name} • ${artifact.generatedBy}',
                                style: const TextStyle(color: Colors.white38),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            if (result?.success == true) ...[
              const SizedBox(height: 14),
              const _MessageCard(
                title: 'BAŞARILI',
                message: 'Build almaya hazır iskelet oluşturuldu ve güvenli köke yazıldı.',
                icon: Icons.check_circle,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _MessageCard(
                title: 'HATA',
                message: _errorMessage!,
                icon: Icons.error_outline,
                isError: true,
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'ÖNERİLEN DÜZELTMELER',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: suggestions
                      .map(
                        (suggestion) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $suggestion',
                            style: const TextStyle(color: Colors.white70, height: 1.35),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'ÜRETİM GÜNLÜĞÜ',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: logs
                      .take(30)
                      .map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            log,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const steps = <String>[
      'İstek',
      'Plan',
      'Scaffold',
      'Domain',
      'Application',
      'Presentation',
      'Doğrulama',
      'Yazma',
      'Tamam',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        steps.length,
        (index) => Chip(
          label: Text(steps[index]),
          avatar: index < activeStep
              ? const Icon(Icons.check, size: 15, color: Colors.cyanAccent)
              : index == activeStep
                  ? const Icon(Icons.play_arrow, size: 15, color: Colors.white)
                  : null,
          labelStyle: TextStyle(
            color: index == activeStep ? Colors.white : Colors.white70,
            fontWeight: index == activeStep ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: index == activeStep
              ? const Color(0xFF007C91)
              : const Color(0xFF10232F),
          side: BorderSide(
            color: index == activeStep ? Colors.cyanAccent : Colors.white12,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      labelStyle: const TextStyle(color: Colors.white70),
      backgroundColor: const Color(0xFF10232F),
      side: const BorderSide(color: Colors.white12),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.icon,
    this.isError = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isError ? Colors.redAccent : Colors.cyanAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.redAccent.shade100 : Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```


## `lib/domain/ai/ai_registry_entry.dart`

```text
/// Minimal immutable registry entry shared by AI catalogue views.
class AiRegistryEntry {
  /// Creates an AI registry entry.
  const AiRegistryEntry({
    required this.id,
    required this.name,
    required this.provider,
    this.model,
    this.description = '',
  });

  /// Stable registry identifier.
  final String id;

  /// Display name.
  final String name;

  /// Provider name.
  final String provider;

  /// Optional model identifier.
  final String? model;

  /// Human-readable description.
  final String description;
}
```


## `lib/domain/testing/integration_test_result.dart`

```text
/// Status of a runtime integration check.
enum IntegrationTestStatus {
  /// The check passed.
  passed,

  /// The check failed.
  failed,
}

/// Result of one integration check.
class IntegrationTestResult {
  /// Creates an immutable integration test result.
  const IntegrationTestResult({
    required this.testId,
    required this.status,
    required this.message,
    required this.completedAt,
  });

  /// Stable test identifier.
  final String testId;

  /// Check status.
  final IntegrationTestStatus status;

  /// Human-readable result message.
  final String message;

  /// Completion timestamp.
  final DateTime completedAt;

  /// Whether the check passed.
  bool get passed => status == IntegrationTestStatus.passed;
}
```


## `lib/application/memory/persistent_memory_repository.dart`

```text
import '../../domain/memory/memory_record.dart';
import '../../domain/memory/memory_scope.dart';
import '../../domain/memory/memory_type.dart';
import '../database/database_manager.dart';
import '../persistence/persistent_repository.dart';
import 'memory_repository.dart';

class PersistentMemoryRepository implements MemoryRepository {
  PersistentMemoryRepository(DatabaseManager database)
      : _repository = PersistentRepository(database);

  final PersistentRepository _repository;

  static const String entityType = 'memory';

  @override
  Future<void> save(MemoryRecord memory) async {
    await _repository.save(
      EntityRecordAdapter.toEntity(memory),
    );
  }

  @override
  Future<MemoryRecord?> getById(String id) async {
    final record = await _repository.getById(entityType, id);
    return record == null ? null : EntityRecordAdapter.fromEntity(record);
  }

  @override
  Future<List<MemoryRecord>> getAll() async {
    final records = await _repository.getAll(entityType);
    return records.map(EntityRecordAdapter.fromEntity).toList();
  }

  @override
  Future<List<MemoryRecord>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final all = await getAll();

    if (normalized.isEmpty) return all;

    return all
        .where(
          (memory) =>
              memory.content.toLowerCase().contains(normalized) ||
              memory.tags.any(
                (tag) => tag.toLowerCase().contains(normalized),
              ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> archive(String id) async {
    final current = await getById(id);
    if (current == null) return;
    await save(current.copyWith(archived: true));
  }

  @override
  Future<void> remove(String id) {
    return _repository.delete(entityType, id);
  }
}

class EntityRecordAdapter {
  const EntityRecordAdapter._();

  static EntityRecord toEntity(MemoryRecord memory) {
    return EntityRecord(
      id: memory.id,
      entityType: PersistentMemoryRepository.entityType,
      createdAt: memory.createdAt,
      updatedAt: DateTime.now().toUtc(),
      data: <String, Object?>{
        'content': memory.content,
        'type': memory.type.name,
        'scope': memory.scope.name,
        'projectId': memory.projectId,
        'taskId': memory.taskId,
        'confidence': memory.confidence,
        'source': memory.source,
        'tags': memory.tags,
        'archived': memory.archived,
      },
    );
  }

  static MemoryRecord fromEntity(EntityRecord entity) {
    final data = entity.data;

    return MemoryRecord(
      id: entity.id,
      content: data['content'] as String? ?? '',
      type: MemoryType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => MemoryType.fact,
      ),
      scope: MemoryScope.values.firstWhere(
        (value) => value.name == data['scope'],
        orElse: () => MemoryScope.personal,
      ),
      createdAt: entity.createdAt,
      projectId: data['projectId'] as String?,
      taskId: data['taskId'] as String?,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
      source: data['source'] as String?,
      tags: List<String>.from(
        (data['tags'] as List<Object?>?) ?? const <Object?>[],
      ),
      archived: data['archived'] as bool? ?? false,
    );
  }
}
```


## `test/application/codegen/code_generation_orchestrator_test.dart`

```text
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/application/codegen/code_generation_orchestrator.dart';
import '../../../lib/application/codegen/code_validator_service.dart';
import '../../../lib/application/codegen/code_writer_service.dart';
import '../../../lib/application/codegen/project_scaffold_service.dart';
import '../../../lib/application/codegen/project_spec_from_request.dart';
import '../../../lib/application/codegen/prompt_builder_service.dart';
import '../../../lib/core/security/cost_policy.dart';
import '../../../lib/domain/codegen/architecture_type.dart';
import '../../../lib/domain/codegen/project_spec.dart';
import '../../../lib/infrastructure/codegen/file_system_writer.dart';
import '../../../lib/infrastructure/codegen/llm_code_generator.dart';

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

ProjectSpec _counterSpec() => const ProjectSpec(
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


## `test/application/codegen/ai_gateway_adapter_test.dart`

```text
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/security/cost_policy.dart';
import '../../../lib/domain/ai/ai_request.dart';
import '../../../lib/infrastructure/codegen/fallback_llm_code_generator.dart';
import '../../../lib/infrastructure/codegen/free_remote_ai_gateway_adapter.dart';
import '../../../lib/infrastructure/codegen/local_ai_gateway_adapter.dart';
import '../../../lib/infrastructure/codegen/llm_code_generator.dart';
import '../../../lib/infrastructure/codegen/openai_compatible_transport.dart';
import '../../../lib/application/codegen/prompt_builder_service.dart';
import '../../../lib/domain/codegen/project_spec.dart';
import '../../../lib/domain/codegen/code_artifact.dart';
import '../../../lib/domain/codegen/architecture_type.dart';
import '../../../lib/core/result/ares_result.dart';
import '../../../lib/domain/ai/ai_response.dart';

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
      projectSpec: const ProjectSpec(
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


## `test/presentation/code_generation_screen_test.dart`

```text
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/domain/codegen/code_artifact.dart';
import '../../lib/domain/codegen/generation_result.dart';
import '../../lib/domain/codegen/artifact_type.dart';
import '../../lib/presentation/codegen/code_generation_screen.dart';

void main() {
  testWidgets('CodeGenerationScreen onGenerate callback gerçekten çağrılır', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CodeGenerationScreen(
          onGenerate: (request, {onProgress}) async {
            called = request == 'Basit bir Counter uygulaması üret';
            onProgress?.call('Tamam');
            return const GenerationResult(
              success: true,
              artifacts: <CodeArtifact>[
                CodeArtifact(
                  relativePath: 'lib/main.dart',
                  content: 'void main() {}',
                  type: ArtifactType.dart,
                  generatedBy: 'test',
                ),
              ],
              errors: <String>[],
              metrics: <String, Object?>{},
            );
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Basit bir Counter uygulaması üret');
    await tester.tap(find.text('ÜRET'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(find.text('Build almaya hazır iskelet oluşturuldu ve güvenli köke yazıldı.'), findsOneWidget);
  });
}
```


## `PROJECT_SUMMARY.md`

```text
# DEST-OS ARES — Kod Üretim Motoru Son Durum

Kod Üretim Motoru artık ana ARES arayüzünden gerçek bir üretim zinciri olarak çalışacak şekilde bağlanmıştır.

## Kullanım

`KOD ÜRETİM MERKEZİ` → yüksek seviye istek → ProjectSpec → ajanlar → local/free AI → validator/self-healing → build readiness → güvenli writer → GenerationResult.

## AI yolları

1. Yerel OpenAI-compatible endpoint: Ollama veya LM Studio.
2. Yerel yol başarısızsa yapılandırılmış ücretsiz/sınırlı ücretsiz remote endpoint.
3. Paid/unknown yol otomatik seçilmez; mevcut PaidAiRuntimeGate ve DecisionEngine zorunludur.
4. Mock yalnızca testlerde bulunur.

## Ajan zinciri

Product Manager → System Architect → Flutter Developer → QA Engineer → DevOps / Release.

Her ajan role-specific prompt alır ve kendi sorumluluk alanındaki artifact'leri üretir.

## Kalite

CodeValidatorService ve BuildReadinessService birlikte kullanılır. Build readiness en az main.dart, pubspec.yaml, analysis_options.yaml, presentation ekranı ve kritik relative importları kontrol eder.

Üretilen proje ayrıca `docs/BUILD_READINESS.md` dosyasını içerir.

## Güvenlik

- Path traversal engellenir.
- Varsayılan yazma davranışı mevcut dosyanın üzerine yazmaz.
- API key kaynak koda gömülmez.
- UI provider'a doğrudan erişmez.
- Paid/unknown AI açık onay olmadan çalıştırılmaz.

## İlk örnek

İstek:

> Basit bir Counter uygulaması üret

Beklenen temel dosyalar:

```text
lib/main.dart
lib/app/app.dart
lib/domain/counter_model.dart
lib/application/counter_service.dart
lib/presentation/counter_screen.dart
pubspec.yaml
analysis_options.yaml
```

Ek olarak ajan çıktıları ve build hazırlık belgeleri `docs/` ve `test/generated/` altında bulunabilir.

## Ortam bağımlılığı

Gerçek AI üretimi için kullanıcının Ollama/LM Studio gibi bir yerel OpenAI-compatible sunucuyu veya yapılandırılmış ücretsiz remote sağlayıcıyı erişilebilir hale getirmesi gerekir. Flutter analyze/test/APK build için Flutter SDK gerekir. Bunlar yazılım eksikliği değil, çalıştırma ortamı bağımlılıklarıdır.

## SON KONTROL LİSTESİ

- [x] Uygulama girişinde gerçek Code Generation facade'ı bağlı
- [x] Local AI adapter
- [x] Free remote adapter
- [x] Local → Free fallback
- [x] Mock yalnızca testte
- [x] ProjectSpec dönüşümü
- [x] Ajan görev zinciri
- [x] Validator
- [x] Self-healing
- [x] Build readiness
- [x] Güvenli writer
- [x] Paid AI Gate
- [x] Testler
- [x] Kurulum dokümantasyonu
```
