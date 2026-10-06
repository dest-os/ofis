# DEST-OS ARES — Tablet Kurulum ve İlk Kullanım

Bu kılavuz kod bilmeden uygulanacak şekilde hazırlanmıştır.

## 1. APK'yı tablete kur

1. GitHub Actions içinden oluşturulan APK'yı indir.
2. APK'yı tablete gönder.
3. APK'ya dokun ve kurulumu tamamla.
4. Android izin sorarsa gerekli izinleri onayla.
5. ARES açıldığında **Ana Ofis** ekranını görmelisin.

## 2. Yerel AI'yı hazırla

ARES'in birincil AI'sı yerel Qwen Coder'dır.

Önerilen başlangıç modeli:

`qwen2.5-coder:1.5b`

Ollama kullanılacaksa bilgisayara Ollama kurulmalı ve model indirilmelidir. Tablet ile Ollama aynı cihazda değilse, Ayarlar bölümündeki **Yerel AI adresi** alanına bilgisayarın ağ adresi yazılmalıdır. Android tablette `127.0.0.1` yalnızca Ollama gerçekten tabletin kendisinde çalışıyorsa doğrudur.

Ardından:

**Sistem & API Ayarları → Genel Ayarlar → Yerel AI → Kaydet ve Test Et**

Sonuç **Hazır** olmalıdır.

## 3. İlk mobil üretim denemesi

Ana Ofis → **Mobil Üret**.

Örnek istek:

> Basit bir not uygulaması üret. Ana ekranda not ekleme ve notları listeleme olsun.

**ÜRET** düğmesine bas.

Üretim sonunda ARES sana:

- çıktı klasörünü,
- üretimin başarılı/başarısız olduğunu,
- çalıştırma adımlarını,
- üretilen dosyaları

göstermelidir.

## 4. İlk video paketi denemesi

Ana Ofis → **Video Paketi**.

Video paketi; senaryo, çekim listesi, altyazı, varlık planı ve render planını oluşturur.

Gerçek video render için ayrıca FFmpeg gerekir. FFmpeg yoksa ARES bunu **eksik** olarak gösterir ve paket üretimini yine yapabilir.

**Render'ı başlat** düğmesi yalnızca açık kullanıcı onayından sonra çalışır.

## 5. İlk 10 dakika testi

- [ ] ARES açılıyor.
- [ ] Ana Ofis ekranı düzgün görünüyor.
- [ ] Sistem Durumu kartı okunuyor.
- [ ] Yerel AI adresi ve model adı doğru.
- [ ] Yerel AI testi **Hazır** diyor.
- [ ] Sohbet ekranından kısa bir soru gönderildi.
- [ ] **Mobil Üret** ile küçük bir proje üretildi.
- [ ] Çıktı klasörü gösterildi.
- [ ] Video paketi oluşturuldu.
- [ ] FFmpeg durumu görüldü.
- [ ] Ayarlar ekranındaki model sırası doğru görünüyor.

## Sorun giderme

### AI yok

Ayarlar ekranını aç. Yerel AI'ı etkinleştir. Adres ve model adını kontrol et. **Kaydet ve Test Et** düğmesine bas.

### AI bağlantısı var ama model bulunamadı

Ollama tarafında `qwen2.5-coder:1.5b` modelinin gerçekten kurulu olduğundan emin ol. Model adı ARES'teki model adıyla aynı olmalı.

### Tablet Ollama'ya bağlanamıyor

Ollama bilgisayarda çalışıyorsa tablet ve bilgisayarın aynı ağda olduğundan emin ol. `127.0.0.1` yerine bilgisayarın yerel ağ adresini kullan.

### FFmpeg yok

Video paketi üretilebilir. Gerçek render için FFmpeg kurulmalı ve çalıştırılabilir olmalıdır.

### İzin sorunu

Android'in uygulama için gösterdiği izin ekranını aç ve istenen izni ver. İzin daha önce reddedildiyse Android uygulama ayarlarından izinleri tekrar kontrol et.

### Ücretli AI konusu

Ücretli veya fiyatı bilinmeyen AI otomatik çalıştırılmaz. Önce hangi AI'ın kullanılacağı ve neden gerektiği gösterilir; açık İbrahim onayı olmadan çalıştırılmaz.
