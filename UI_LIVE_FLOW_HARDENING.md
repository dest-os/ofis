# ARES Canlı Akış Arayüz Sertleştirmesi

- Canlı durum, adımlar, sonuç, hata ve günlük ayrı dikey alanlara ayrıldı.
- Üretilen dosya ve uzun günlükler sınırlı yükseklikte kaydırılabilir alanlara alındı.
- Uzun metinlerde `maxLines` ve `TextOverflow.ellipsis` kullanıldı.
- Üretim sırasında giriş ve üretim butonu devre dışı bırakıldı; eski `ÜRET` metni görünmez.
- Tablet kartlarında 16 dp aralık korunuyor.
- `Positioned` ile çakıştırma kullanılmadı.
