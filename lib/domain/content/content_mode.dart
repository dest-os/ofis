/// ARES üretim merkezinde desteklenen içerik modlarıdır.
enum ContentMode { mobileApp, video, general }

extension ContentModeLabel on ContentMode {
  /// Kullanıcı arayüzünde gösterilen Türkçe ad.
  String get label {
    switch (this) {
      case ContentMode.mobileApp:
        return 'Mobil Uygulama Üret';
      case ContentMode.video:
        return 'Video İçerik Üret';
      case ContentMode.general:
        return 'Genel İçerik Üret';
    }
  }
}
