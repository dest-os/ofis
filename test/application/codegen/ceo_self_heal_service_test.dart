import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/ceo/ceo_self_heal_service.dart';
import 'package:dest_os_ares/application/codegen/code_validator_service.dart';
import 'package:dest_os_ares/core/result/ares_result.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/codegen/code_artifact.dart';
import 'package:dest_os_ares/infrastructure/codegen/llm_code_generator.dart';

void main() {
  test('CEO teşhisi Türkçe olur ve üç denemeyle sınırlıdır', () {
    const service = CeoSelfHealService(llmCodeGenerator: _FakeGenerator());
    final report = CodeValidationReport(
      errors: const <String>['main.dart bulunamadı.'],
      suggestedActions: const <String>['main.dart oluştur.'],
    );

    expect(service.diagnose(report), contains('Ana başlangıç dosyasında sorun'));
    expect(service.buildInstruction(report), contains('CEO DÜZELTME TALİMATI'));
    expect(CeoSelfHealService.maxAttempts, 3);
  });
}

class _FakeGenerator implements LlmCodeGenerator {
  const _FakeGenerator();

  @override
  Future<AresResult<List<CodeArtifact>>> generate(
    CodegenPrompt prompt, {
    AiCostClass costClass = AiCostClass.local,
    String? provider,
    String? model,
  }) async => const AresFailure<List<CodeArtifact>>('test');
}
