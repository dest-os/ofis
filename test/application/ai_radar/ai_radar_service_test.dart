import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/ai_radar/ai_radar_service.dart';
import 'package:dest_os_ares/domain/ai_radar/ai_radar_candidate.dart';

void main() {
  test('AI Radar güvenli katalogda yerel Qwen adayını içerir', () {
    final candidates = const AiRadarService().catalog();
    expect(candidates, isNotEmpty);
    expect(candidates.any((item) => item.model == 'qwen2.5-coder:1.5b'), isTrue);
  });

  test('AI Radar kataloğunda otomatik ücretli aday yoktur', () {
    final candidates = const AiRadarService().catalog();
    expect(candidates.every((item) => !item.isPaid), isTrue);
    expect(candidates.every((item) => item.type != AiRadarCandidateType.local || item.model != null), isTrue);
  });
}
