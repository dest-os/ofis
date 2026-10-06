# DEST-OS ARES Flutter V28 – Production Runtime

V28, V1–V27 mimarisinin üzerine üretim çalışma çekirdeğinin temelini ekler.

## Eklenen ana alanlar
- Production Composition Root ve modül kayıt sistemi
- Production Boot / güvenli başlatma ve kapatma
- Task, Agent, CEO, CIO, AI, Tool, Event Bus, Scheduler, Workflow, Android, Voice, Chat ve UI Projection runtime sınırları
- Runtime durum/mod takibi
- Health kontrolü ve heartbeat
- Retry, timeout ve circuit breaker altyapısı
- Online/offline çalışma modu
- Safe Mode / recovery komutları
- Feature Flags ve Runtime Config
- Paid AI / UNKNOWN için son çalışma kapısı
- Basit Production Runtime ekranı
- V28 testleri

## Değişmez maliyet kuralı
PAID ve UNKNOWN AI, kullanıcı açıkça onaylamadan çalıştırılamaz. Bu V28'de ayrı bir runtime kapısı olarak korunur.

## Önemli teknik not
Bu aşamada gerçek Android Foreground Service, gerçek SQLite, gerçek ağ sağlayıcıları veya ücretli AI sağlayıcıları otomatik bağlanmamıştır. V28 bunların üretim runtime sınırlarını ve güvenli orkestrasyon temelini oluşturur. Gerçek adaptörler sonraki üretim sertleştirme aşamalarında bağlanacaktır.

## Test notu
Bu çalışma ortamında Flutter SDK bulunmadığı için `flutter test` çalıştırılmamıştır. ZIP bütünlüğü kontrol edilmiştir.
