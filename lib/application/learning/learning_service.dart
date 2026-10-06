import '../../domain/learning/learning_observation.dart';
import '../../domain/learning/learning_pattern.dart';
import '../../domain/learning/learning_recommendation.dart';
import '../../domain/learning/performance_record.dart';
import 'learning_guard.dart';
import 'learning_repository.dart';

class LearningService {
  final LearningRepository repository;
  final LearningGuard guard;

  LearningService({required this.repository, this.guard = const LearningGuard()});

  Future<PerformanceRecord> recordObservation(LearningObservation observation) async {
    await repository.saveObservation(observation);
    final current = await repository.performanceFor(observation.subjectId);
    final next = current ?? PerformanceRecord(
      subjectId: observation.subjectId,
      subjectType: observation.sourceType.name,
      sampleCount: 0,
      successRate: 0,
      averageScore: 0,
      updatedAt: observation.observedAt,
    );
    final updated = next.addSample(
      success: observation.success,
      score: observation.score,
      at: observation.observedAt,
    );
    await repository.savePerformance(updated);
    return updated;
  }

  Future<LearningRecommendation?> recommendImprovement({
    required String targetType,
    required String targetId,
    required String action,
    required double confidence,
    required String reason,
  }) async {
    final guardResult = guard.evaluate(proposedChange: action);
    if (!guardResult.allowed) return null;
    return LearningRecommendation(
      id: '${targetType}_$targetId',
      targetType: targetType,
      targetId: targetId,
      action: action,
      confidence: confidence,
      requiresReview: confidence < 0.80 || guardResult.requiresReview,
      reason: reason,
    );
  }

  Future<void> registerPattern(LearningPattern pattern) => repository.savePattern(pattern);
}
