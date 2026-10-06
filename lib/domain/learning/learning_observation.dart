import 'learning_source_type.dart';

class LearningObservation {
  final String id;
  final LearningSourceType sourceType;
  final String subjectId;
  final String? taskId;
  final String? agentId;
  final double score;
  final bool success;
  final String summary;
  final DateTime observedAt;

  const LearningObservation({
    required this.id,
    required this.sourceType,
    required this.subjectId,
    required this.score,
    required this.success,
    required this.summary,
    required this.observedAt,
    this.taskId,
    this.agentId,
  });
}
