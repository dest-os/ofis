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
          actions.add("$path: $importPath importunu mevcut bir artifact dosyasına yönelt veya gerekli dosyayı üret.");
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
