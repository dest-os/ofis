# DEST-OS ARES Flutter — V29 Notları

## V29 — Backup / Update / Migration

V28 Production Runtime üzerine kümülatif olarak eklenmiştir.

- Üretim yedeği manifesti ve bütünlük kontrolü
- Şifreli yedek zorunluluğu için güvenlik kapısı
- Migration planı ve yıkıcı migration için açık onay kapısı
- Update channel / update planı
- Güncelleme imza ve bütünlük kontrolü
- Üretim kurtarma ekranı

Kurallar: Ücretli AI otomatik etkinleştirilemez. Gizli bilgiler düz metin yedekte/logda tutulmaz. Yıkıcı geri yükleme/migration açık onaysız uygulanmaz. Güncelleme imza ve bütünlük kontrolünü geçmeden kurulmaz.

Gerçek bulut yedeklemesi veya gerçek cihaz güncellemesi bu aşamada çalıştırılmaz; güvenli sözleşme ve kapı katmanı hazırlanır.

Sonraki aşama: V30 — Integration Test / Hardening.
