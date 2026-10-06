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
