import '../../core/format/tr_date.dart';
import '../../core/ids/ares_id.dart';
import '../../domain/archive/work_archive_entry.dart';
import '../../domain/codegen/generation_result.dart';
import 'secret_scrubber.dart';
import 'work_archive_repository.dart';

/// Biten işleri tarih başlıklı kısa özetlerle arşive yazar. Asla hata fırlatmaz.
class ArchiveRecorder {
  ArchiveRecorder(this.archive, {this.scrubber = const SecretScrubber()});

  final WorkArchiveRepository archive;
  final SecretScrubber scrubber;

  /// Mobil uygulama üretimi sonucunu kaydeder.
  Future<void> recordCodeGeneration({required String request, required GenerationResult result}) {
    final paths = result.artifacts.map((a) => a.relativePath).take(8).join(', ');
    final errors = result.errors.take(2).map((e) => clipText(e, 160)).join(' | ');
    final summary = StringBuffer()
      ..write('Mobil uygulama üretimi. İstek: ${clipText(request, 200)}. ')
      ..write(result.success ? 'Sonuç: başarılı. ' : 'Sonuç: başarısız. ')
      ..write('Dosya sayısı: ${result.artifacts.length}.');
    if (paths.isNotEmpty) summary.write(' Dosyalar: $paths.');
    if (errors.isNotEmpty) summary.write(' Hatalar: $errors.');
    return _save(
      idPrefix: 'code',
      request: request,
      summary: summary.toString(),
      tags: <String>['kod üretimi', result.success ? 'başarılı' : 'başarısız'],
      reusable: result.success,
    );
  }

  /// Video / genel içerik üretimi sonucunu kaydeder.
  Future<void> recordContent({
    required String modeLabel,
    required String request,
    required bool success,
    required int artifactCount,
    required List<String> errors,
  }) {
    final summary = StringBuffer()
      ..write('$modeLabel. İstek: ${clipText(request, 200)}. ')
      ..write(success ? 'Sonuç: başarılı. ' : 'Sonuç: başarısız. ')
      ..write('Dosya sayısı: $artifactCount.');
    final errorText = errors.take(2).map((e) => clipText(e, 160)).join(' | ');
    if (errorText.isNotEmpty) summary.write(' Hatalar: $errorText.');
    return _save(
      idPrefix: 'content',
      request: request,
      summary: summary.toString(),
      tags: <String>['içerik üretimi', success ? 'başarılı' : 'başarısız'],
      reusable: success,
    );
  }

  Future<void> _save({
    required String idPrefix,
    required String request,
    required String summary,
    required List<String> tags,
    required bool reusable,
  }) async {
    try {
      final now = DateTime.now();
      await archive.save(
        WorkArchiveEntry(
          id: AresId('${idPrefix}_${now.microsecondsSinceEpoch}'),
          title: '${formatTrDate(now)} — ${clipText(scrubber.scrub(request), 40)}',
          summary: scrubber.scrub(summary),
          completedAt: now,
          tags: tags,
          reusable: reusable,
        ),
      );
    } catch (_) {
      // Arşiv yazılamazsa asıl iş sonucu etkilenmesin.
    }
  }
}
