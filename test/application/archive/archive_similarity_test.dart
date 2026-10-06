import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/archive/archive_similarity.dart';
import 'package:dest_os_ares/application/archive/secret_scrubber.dart';
import 'package:dest_os_ares/core/ids/ares_id.dart';
import 'package:dest_os_ares/domain/archive/work_archive_entry.dart';

WorkArchiveEntry _entry(String id, String title, String summary, {bool reusable = true}) => WorkArchiveEntry(
      id: AresId(id),
      title: title,
      summary: summary,
      completedAt: DateTime(2026, 10, 1),
      reusable: reusable,
    );

void main() {
  test('Türkçe eklere rağmen benzer kayıt bulunur', () {
    final entries = [
      _entry('a', '01 Ekim 2026 — görev takip uygulaması', 'Mobil uygulama üretimi. İstek: görev takip uygulaması yap.'),
      _entry('b', '02 Ekim 2026 — yemek tarifi', 'Tarif listesi hazırlandı.'),
    ];
    final result = const ArchiveSimilarity().rank('görevleri takip eden bir uygulama yapmak istiyorum', entries);
    expect(result, isNotEmpty);
    expect(result.first.entry.id.value, 'a');
  });

  test('alakasız istek eşleşmez ve tek kelime tesadüfü yok sayılır', () {
    final entries = [_entry('a', 'görev takip uygulaması', 'görev takip uygulaması')];
    expect(const ArchiveSimilarity().rank('hava durumu nasıl', entries), isEmpty);
    expect(const ArchiveSimilarity().rank('uygulama', entries), isEmpty);
  });

  test('yeniden kullanılamaz kayıt önerilmez', () {
    final entries = [_entry('a', 'görev takip uygulaması', 'görev takip uygulaması', reusable: false)];
    expect(const ArchiveSimilarity().rank('görev takip uygulaması yap', entries), isEmpty);
  });

  test('gizli değerler arşive girmeden temizlenir', () {
    const scrubber = SecretScrubber();
    final cleaned = scrubber.scrub('anahtar sk-abcdefghijklmnopqrstuvwxyz123456 ve şifre: 1234 ve Bearer abcdefghijklmnopqrstuv');
    expect(cleaned.contains('sk-abc'), isFalse);
    expect(cleaned.contains('1234'), isFalse);
    expect(cleaned.contains('abcdefghijklmnopqrstuv'), isFalse);
    expect(cleaned.contains('[GİZLİ]'), isTrue);
  });
}
