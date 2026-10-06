# Prompt 01 – Kod Üretim Motoru Domain Modelleri

Bu aşamada yalnızca `lib/domain/codegen/` altında Kod Üretim Motoru için temel domain modelleri oluşturuldu.

Oluşturulan dosyalar:
- architecture_type.dart
- artifact_type.dart
- project_spec.dart
- code_artifact.dart
- generation_plan.dart
- generation_result.dart
- quality_gate.dart

Kurallar:
- Servis, repository veya presentation kodu eklenmedi.
- Harici paket eklenmedi; immutable koleksiyonlar Dart'ın `List.unmodifiable` ve `Map.unmodifiable` araçlarıyla korunuyor.
- `copyWith` metotları eklendi.
- Mevcut ARES `AresId` ve `AresResult` yapıları değiştirilmedi.
