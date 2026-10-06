import 'artifact_type.dart';

/// Kod üretim motorunun oluşturduğu tek bir dosyayı temsil eder.
class CodeArtifact {
  /// Creates an immutable generated-file description.
  const CodeArtifact({
    required this.relativePath,
    required this.content,
    required this.type,
    required this.generatedBy,
  });

  /// Project-relative path of the generated file.
  final String relativePath;

  /// Complete text content of the generated file.
  final String content;

  /// Format of the generated file.
  final ArtifactType type;

  /// Agent or service that produced the artifact.
  final String generatedBy;

  /// Returns a copy with the supplied fields replaced.
  CodeArtifact copyWith({
    String? relativePath,
    String? content,
    ArtifactType? type,
    String? generatedBy,
  }) {
    return CodeArtifact(
      relativePath: relativePath ?? this.relativePath,
      content: content ?? this.content,
      type: type ?? this.type,
      generatedBy: generatedBy ?? this.generatedBy,
    );
  }
}
