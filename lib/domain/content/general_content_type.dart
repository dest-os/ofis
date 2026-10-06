/// Genel içerik üretiminde desteklenen standart türler.
enum GeneralContentType { appIdea, marketing, postSeries, productDescription }

extension GeneralContentTypeLabel on GeneralContentType {
  /// Kullanıcıya gösterilen ad.
  String get label {
    switch (this) {
      case GeneralContentType.appIdea:
        return 'Uygulama Fikri Dokümanı';
      case GeneralContentType.marketing:
        return 'Pazarlama Metni';
      case GeneralContentType.postSeries:
        return 'Post Serisi';
      case GeneralContentType.productDescription:
        return 'Ürün Açıklaması';
    }
  }
}
