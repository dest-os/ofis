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
    final importPattern = RegExp("import\s+['\"]([^'\"]+)['\"];");
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
