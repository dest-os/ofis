const List<String> _trMonths = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

/// "06 Ekim 2026" biçiminde gün-ay-yıl başlığı üretir.
String formatTrDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${_trMonths[date.month - 1]} ${date.year}';
}

/// Metni en fazla [max] karaktere kısaltır (tek satıra indirger).
String clipText(String value, int max) {
  final flat = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.length <= max) return flat;
  return '${flat.substring(0, max)}…';
}
