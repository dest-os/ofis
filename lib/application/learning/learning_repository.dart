import '../../domain/learning/learning_observation.dart';
import '../../domain/learning/learning_pattern.dart';
import '../../domain/learning/performance_record.dart';

abstract class LearningRepository {
  Future<void> saveObservation(LearningObservation observation);
  Future<List<LearningObservation>> observationsFor(String subjectId);
  Future<void> savePerformance(PerformanceRecord record);
  Future<PerformanceRecord?> performanceFor(String subjectId);
  Future<void> savePattern(LearningPattern pattern);
  Future<List<LearningPattern>> patterns();
}
