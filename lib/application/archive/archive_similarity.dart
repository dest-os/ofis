import '../../domain/archive/work_archive_entry.dart';

/// Yeni isteğe benzeyen eski bir arşiv kaydı ve benzerlik puanı.
class ArchiveMatch {
  const ArchiveMatch({required this.entry, required this.score});

  final WorkArchiveEntry entry;
  final double score;
}

/// Türkçe eklere dayanıklı basit kelime kökü eşleştirmesi.
///
/// Kelimeler küçük harfe çevrilir, ilk 5 harfi (kök) alınır ve ortak kök
/// sayısına göre puanlanır. "görevler" ile "görevi" aynı kökte buluşur.
class ArchiveSimilarity {
  const ArchiveSimilarity({this.minScore = 0.5, this.minShared = 2});

  /// Sorgunun köklerinin en az bu oranı kayıtta bulunmalı.
  final double minScore;

  /// Ortak kök sayısı en az bu kadar olmalı (tek kelimelik tesadüfü engeller).
  final int minShared;

  static const Set<String> _stopWords = <String>{
    'için', 'gibi', 'olan', 'lütfen', 'bana', 'istiyorum', 'yapmak', 'nasıl',
    'şunu', 'bunu', 'ama', 'çok', 'daha', 'bir', 'ile', 'yap', 'yapar',
  };

  /// Metni kök kümesine çevirir.
  static Set<String> stems(String text) {
    final lower = text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final words = lower.split(RegExp(r'[^a-z0-9çğıöşü]+'));
    final result = <String>{};
    for (final word in words) {
      if (word.length < 3 || _stopWords.contains(word)) continue;
      result.add(word.length > 5 ? word.substring(0, 5) : word);
    }
    return result;
  }

  /// [entries] içinden [query]'ye en çok benzeyenleri puana göre döndürür.
  List<ArchiveMatch> rank(String query, Iterable<WorkArchiveEntry> entries, {int limit = 3}) {
    final queryStems = stems(query);
    if (queryStems.length < minShared) return const <ArchiveMatch>[];
    final matches = <ArchiveMatch>[];
    for (final entry in entries) {
      if (entry.isDeleted || !entry.reusable) continue;
      final entryStems = stems('${entry.title} ${entry.summary} ${entry.tags.join(' ')}');
      final shared = queryStems.where(entryStems.contains).length;
      final score = shared / queryStems.length;
      if (shared >= minShared && score >= minScore) {
        matches.add(ArchiveMatch(entry: entry, score: score));
      }
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit).toList(growable: false);
  }
}
