# DEST-OS ARES V32 — Adım 1 Notları

Bu sürümde yapılanlar (V31 incelemesindeki eksiklere göre):

1. **Ayarlar ekranı** (CEO masası): adres, model, API anahtarı, yerel AI anahtarı, "Kaydet ve test et".
   Ayarlar cihazda kalıcıdır; uygulamayı yeniden derlemeden değişir.
2. **Sohbet ekranı** (Dinleyici masası): mesaj gerçekten yapay zekâya gider, cevap görünür, hata Türkçe gösterilir.
3. **Eğitim / Arşiv**: kayıtlar "06 Ekim 2026 — konu" başlığıyla, diskte kalıcı, yanında sil simgesi (onaylı),
   90 günden eskiler için hatırlatma. API anahtarı/parola benzeri metinler kaydedilmeden gizlenir.
4. **Benzer çalışma önerisi**: yeni sohbetin ilk mesajı arşivle eşleşirse "referans olarak kullanılsın mı?" diye sorar;
   evet denirse yalnızca kısa özet gönderilir (token tasarrufu).
5. **Ajanlar birbirinin çıktısını görür**: her aşamaya önceki dosyalardan kısaltılmış alıntılar eklenir (toplam ~6000 karakter).
6. Kod/içerik üretimi bitince sonuç otomatik arşive yazılır.
7. `allowBackup=false`: API anahtarı bulut yedeğine karışmasın.

Henüz yapılmayanlar: CEO'nun hata yorumlayıp 3 kez düzeltme talimatı vermesi ve ayrıntılı rapor, canlı operasyon panosu,
AI Radar (internetten yeni model bulma), sesli komut, gerçek derleme kontrolü, anahtarın şifreli depoda saklanması.

DİKKAT: Bu sürüm Flutter kurulu olmayan ortamda yazıldı; derlenmedi ve testler çalıştırılmadı.
İlk iş GitHub Actions derlemesini çalıştırın; hata çıkarsa günlüğü olduğu gibi iletin.
