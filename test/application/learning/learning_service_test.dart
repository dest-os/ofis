import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/learning/in_memory_learning_repository.dart';
import 'package:dest_os_ares/application/learning/learning_service.dart';
import 'package:dest_os_ares/domain/learning/learning_observation.dart';
import 'package:dest_os_ares/domain/learning/learning_source_type.dart';

void main() {
  test('öğrenme gözlemi performans kaydı oluşturur', () async {
    final service = LearningService(repository: InMemoryLearningRepository());
    final record = await service.recordObservation(
      LearningObservation(
        id: 'obs-1',
        sourceType: LearningSourceType.taskOutcome,
        subjectId: 'agent-1',
        score: 0.9,
        success: true,
        summary: 'Görev başarıyla tamamlandı.',
        observedAt: DateTime(2026, 1, 1),
      ),
    );
    expect(record.sampleCount, 1);
    expect(record.successRate, 1);
  });

  test('öğrenme güvenliği ücretli AI değişikliğini engeller', () async {
    final service = LearningService(repository: InMemoryLearningRepository());
    final recommendation = await service.recommendImprovement(
      targetType: 'ai',
      targetId: 'model-1',
      action: 'paid ai etkinleştir',
      confidence: 0.99,
      reason: 'Daha yüksek kalite.',
    );
    expect(recommendation, isNull);
  });
}
