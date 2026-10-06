import '../../domain/codegen/code_artifact.dart';
import '../../infrastructure/codegen/file_system_writer.dart';

/// Sonuç olarak hangi artifact'lerin yazıldığını ve oluşan hataları taşır.
class CodeWriteResult {
  /// Creates an immutable write result.
  const CodeWriteResult({
    required this.writtenPaths,
    required this.errors,
  });

  /// Paths successfully written to disk.
  final List<String> writtenPaths;

  /// Errors or skipped-write messages produced by the writer.
  final List<String> errors;

  /// Whether no write errors were reported.
  bool get success => errors.isEmpty;

  /// Returns a copy with the supplied fields replaced.
  CodeWriteResult copyWith({
    List<String>? writtenPaths,
    List<String>? errors,
  }) {
    return CodeWriteResult(
      writtenPaths: List.unmodifiable(writtenPaths ?? this.writtenPaths),
      errors: List.unmodifiable(errors ?? this.errors),
    );
  }
}

/// CodeArtifact'leri gerçek dosya sistemine yazma işini orkestre eder.
///
/// Bu katman dosya sistemine doğrudan erişmez; gerçek I/O [FileSystemWriter]
/// tarafından gerçekleştirilir.
class CodeWriterService {
  /// Creates a writer service around the infrastructure writer.
  const CodeWriterService({required FileSystemWriter writer}) : _writer = writer;

  final FileSystemWriter _writer;

  /// Writes all supplied artifacts using the configured infrastructure writer.
  Future<CodeWriteResult> writeArtifacts(
    List<CodeArtifact> artifacts, {
    bool overwrite = false,
  }) async {
    final writtenPaths = <String>[];
    final errors = <String>[];

    for (final artifact in artifacts) {
      try {
        final result = await _writer.writeArtifact(
          artifact,
          overwrite: overwrite,
        );
        if (result.written) {
          writtenPaths.add(result.relativePath);
        } else if (result.skipped) {
          errors.add(
            'Dosya atlandı: ${result.relativePath} (üzerine yazma kapalı).',
          );
        }
      } on FileSystemWriterException catch (error) {
        errors.add(error.message);
      } catch (error) {
        errors.add('${artifact.relativePath}: $error');
      }
    }

    return CodeWriteResult(
      writtenPaths: List.unmodifiable(writtenPaths),
      errors: List.unmodifiable(errors),
    );
  }
}
