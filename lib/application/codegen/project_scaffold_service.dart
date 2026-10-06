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
