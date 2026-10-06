# DEST-OS ARES — GitHub İlk Build Rehberi

Bu proje GitHub'a doğrudan proje kökü olarak yüklenecektir.

## Bulunması gereken ana klasörler
- `.github/workflows/`
- `android/`
- `assets/`
- `lib/`
- `test/`

## İlk build
1. Repository'ye proje dosyalarının tamamını yükle.
2. GitHub'da **Actions** sekmesine gir.
3. `ARES APK Build` iş akışını aç.
4. **Run workflow** ile başlat.
5. Önce `flutter pub get`, sonra `flutter analyze`, sonra `flutter test`, ardından release APK build çalışır.
6. Başarılı olursa APK `Artifacts` bölümünden alınır.

## Önemli
Gerçek mağaza/production imzası için keystore GitHub Secrets üzerinden ayrıca bağlanmalıdır. Keystore veya API anahtarı repository'ye yüklenmemelidir.
