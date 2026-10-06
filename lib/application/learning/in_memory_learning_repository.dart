import '../../domain/learning/learning_observation.dart';
import '../../domain/learning/learning_pattern.dart';
import '../../domain/learning/performance_record.dart';
import 'learning_repository.dart';

class InMemoryLearningRepository implements LearningRepository {
  final Map<String, LearningObservation> _observations = {};
  final Map<String, PerformanceRecord> _performance = {};
  final Map<String, LearningPattern> _patterns = {};

  @override
  Future<void> saveObservation(LearningObservation observation) async {
    _observations[observation.id] = observation;
  }

  @override
  Future<List<LearningObservation>> observationsFor(String subjectId) async =>
      _observations.values.where((item) => item.subjectId == subjectId).toList();

  @override
  Future<void> savePerformance(PerformanceRecord record) async {
    _performance[record.subjectId] = record;
  }

  @override
  Future<PerformanceRecord?> performanceFor(String subjectId) async => _performance[subjectId];

  @override
  Future<void> savePattern(LearningPattern pattern) async {
    _patterns[pattern.id] = pattern;
  }

  @override
  Future<List<LearningPattern>> patterns() async => _patterns.values.toList();
}
