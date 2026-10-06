# PROMPT 07 – Kod Üretim Motoru ARES Runtime Entegrasyonu

## Yapılanlar
- `AgentCapability.codeGeneration` eklendi.
- CEO Intent Parser; uygulama üretme, APK yapma, Flutter projesi oluşturma ve benzeri ifadeleri `CeoIntentType.codeGeneration` olarak tanır.
- Code Generation niyeti `AgentCapability.codeGeneration` gerektirir.
- CEO planı ve task tanımı gerekli capability bilgisini taşır.
- `CodeGenerationRuntimeModule` oluşturuldu ve `ProductionCompositionRoot` üzerinden isteğe bağlı gerçek `CodeGenerationOrchestrator` ile runtime registry'ye kaydedilir.
- Orkestratörün içindeki mevcut `AresAiGateway` + `PaidAiRuntimeGate` yolu değiştirilmedi. Ücretli/UNKNOWN AI yine mevcut gate tarafından onay bekler.

## Önemli entegrasyon kararı
ProductionCompositionRoot, kod üretim orkestratörünü doğrudan sahte bir AI sağlayıcısıyla oluşturmaz. Gerçek ARES AI Gateway ile kurulmuş `CodeGenerationOrchestrator` dışarıdan enjekte edilir. Böylece mevcut AI Gateway ve güvenlik/ücret politikası korunur.

## Değiştirilen dosyalar
- `lib/domain/agents/agent_capability.dart`
- `lib/domain/ceo/ceo_intent.dart`
- `lib/application/ceo/ceo_intent_parser.dart`
- `lib/domain/ceo/task_definition.dart`
- `lib/domain/ceo/ceo_plan.dart`
- `lib/application/ceo/ceo_planner.dart`
- `lib/application/runtime/production/production_composition_root.dart`

## Yeni dosya
- `lib/application/codegen/code_generation_runtime_module.dart`

Flutter/Dart SDK bu çalışma ortamında bulunmadığı için `flutter analyze` çalıştırılamadı. ZIP bütünlüğü ayrıca test edilmelidir.
