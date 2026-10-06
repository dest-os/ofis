# DEST-OS ARES V31 — Production Release

V31, V1–V30 mimarisinin üretim sürümüne çıkış kapısını tanımlar.

## Ana kurallar
- Release yalnızca tüm zorunlu kapılar geçtiğinde hazır kabul edilir.
- Production paketi imzalı olmalıdır.
- Release manifesti sürüm, build, artifact ve bütünlük bilgisini taşır.
- V30 entegrasyon, güvenlik, backup/restore ve migration kontrolleri geçmeden yayın yapılmaz.
- Ücretli AI son güvenlik kapısı ayrı ve zorunludur. Açık kullanıcı onayı olmadan ücretli AI etkinleştirilmez.
- Local AI için model, lisans ve release kontrolü zorunludur.
- Hedef 2400×1600 tablet smoke testi release kapılarından biridir.
- Rollback/recovery ve audit üretim hazırlığının parçasıdır.

## V31 kapsamı
- Production Release Gate
- Release Manifest
- Artifact bütünlüğü
- Production imza kontrolü
- Security Gate
- Paid AI Final Gate
- Local AI Release Gate
- Tablet Smoke Gate
- Backup/Restore Gate
- Migration Gate
- Integration Gate
- Release ekranı
- Release servis testleri

Bu sürüm gerçek mağaza yüklemesi veya gerçek ücretli servis satın alımı yapmaz; yalnızca üretim release mimarisini ve güvenlik kapılarını hazırlar.
