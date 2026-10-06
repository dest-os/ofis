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
