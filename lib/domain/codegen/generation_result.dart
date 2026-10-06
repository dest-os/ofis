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
