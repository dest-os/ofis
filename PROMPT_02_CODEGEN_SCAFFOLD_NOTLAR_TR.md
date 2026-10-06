# PROMPT 2 – Kod Üretim Motoru Proje Scaffold Servisi

Bu aşamada `ProjectScaffoldService` eklendi.

## Davranış
- `ProjectSpec` alır.
- Clean Architecture temelindeki dosya yollarını bellek içinde artifact olarak üretir.
- `lib/main.dart`
- `lib/app/app.dart`
- `pubspec.yaml`
- `analysis_options.yaml`
- `CodeArtifact` listesi döndürür.
- Hiçbir dosyayı diske yazmaz.
- Dosya sistemi, ağ veya dış servis kullanmaz.

## Kapsam sınırı
Bu promptta istenmediği için gerçek dosya yazma servisi, repository veya presentation katmanı eklenmedi.

## Not
`ProjectSpec.requiredPackages` içindeki paketler `pubspec.yaml` içinde dependency olarak üretilir. Flutter SDK bağımlılığı ayrıca eklenir.
