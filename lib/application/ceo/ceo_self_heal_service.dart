import '../../core/result/ares_result.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/codegen/code_artifact.dart';
import '../../domain/codegen/project_spec.dart';
import '../codegen/code_validator_service.dart';
import '../codegen/prompt_builder_service.dart';
import '../../infrastructure/codegen/llm_code_generator.dart';

/// CEO'nun kod üretim hatalarını okuyup güvenli düzeltme talimatı üretmesini
/// ve bir sonraki self-heal denemesini yönetmesini sağlar.
class CeoSelfHealService {
  const CeoSelfHealService({
    required LlmCodeGenerator llmCodeGenerator,
    this.costClass = AiCostClass.unknown,
    this.provider,
    this.model,
  }) : _llmCodeGenerator = llmCodeGenerator;

  final LlmCodeGenerator _llmCodeGenerator;
  final AiCostClass costClass;
  final String? provider;
  final String? model;

  static const int maxAttempts = 3;

  String diagnose(CodeValidationReport report) {
    if (report.errors.isEmpty) return 'Üretim kontrolü başarılı; ek düzeltme gerekmiyor.';
    final first = report.errors.first.toLowerCase();
    if (first.contains('main.dart')) return 'Ana başlangıç dosyasında sorun görünüyor.';
    if (first.contains('pubspec')) return 'Projenin temel paket ayarlarında sorun görünüyor.';
    if (first.contains('import') || first.contains('referans')) return 'Dosyalar arasındaki bağlantılardan birinde sorun görünüyor.';
    if (first.contains('sözdiz') || first.contains('syntax') || first.contains('tırnak')) return 'Üretilen kodun yazımında bir hata görünüyor.';
    return 'Üretim kontrolünde bir uyumsuzluk bulundu; sorunlu dosyalar yeniden düzeltiliyor.';
  }

  String buildInstruction(CodeValidationReport report) {
    final errors = report.errors.take(5).join('\n- ');
    final suggestions = report.suggestedActions.take(5).join('\n- ');
    return '''CEO DÜZELTME TALİMATI
Teşhis: ${diagnose(report)}

Öncelik: Aşağıdaki gerçek kontrol hatalarını düzelt.
- $errors

Öneriler:
- $suggestions

Kurallar: Yalnızca gerekli artifact'leri düzelt; güvenlik, çıktı kökü ve ücretli AI onay kapılarını değiştirme.''';
  }

  Future<AresResult<List<CodeArtifact>>> repair({
    required ProjectSpec spec,
    required CodegenAgentRole role,
    required List<CodeArtifact> artifacts,
    required CodeValidationReport report,
  }) async {
    final prompt = CodegenPrompt(
      role: role,
      systemPrompt: '''Sen DEST-OS ARES CEO self-heal katmanısın.
Üretim hatasını incele ve yalnızca hatayı düzelten artifact JSON'u üret.
Çıktı yalnızca geçerli JSON olmalı:
{"artifacts":[{"relativePath":"...","content":"...","type":"dart|yaml|markdown|json|other","generatedBy":"${role.displayName}"}]}
Güvenlik kurallarını, çıktı kökünü ve ücretli AI onayını değiştirme.''',
      userPrompt: '''${buildInstruction(report)}

PROJECT
Ad: ${spec.projectName}
Paket: ${spec.packageName}
Açıklama: ${spec.description}

DÜZELTİLECEK DOSYALAR
${artifacts.map((a) => 'PATH: ${a.relativePath}\nCONTENT:\n${a.content}').join('\n\n')}

Yalnızca düzeltilmiş artifact JSON'unu döndür.''',
    );
    try {
      return await _llmCodeGenerator.generate(
        prompt,
        costClass: costClass,
        provider: provider,
        model: model,
      );
    } catch (error) {
      return AresFailure<List<CodeArtifact>>('CEO düzeltme çağrısı başarısız: $error');
    }
  }
}
