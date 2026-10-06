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
