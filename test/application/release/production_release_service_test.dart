import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/release/production_release_service.dart';
import 'package:dest_os_ares/domain/release/release_manifest.dart';

void main() {
  final service = ProductionReleaseService();

  ReleaseManifest manifest({bool signed = true}) => ReleaseManifest(
        version: '0.1.0',
        buildNumber: '31',
        channel: 'production',
        artifactType: 'apk',
        integrityHash: 'hash',
        createdAt: DateTime(2026, 1, 1),
        signed: signed,
      );

  test('tüm zorunlu kapılar geçerse release hazırdır', () {
    final result = service.evaluate(
      manifest: manifest(),
      integrationPassed: true,
      securityPassed: true,
      backupRestorePassed: true,
      migrationPassed: true,
      paidAiGatePassed: true,
      localAiReleaseCheckPassed: true,
      tabletSmokePassed: true,
    );

    expect(result.ready, isTrue);
    expect(result.blockers, isEmpty);
  });

  test('ücretli AI kapısı başarısızsa release engellenir', () {
    final result = service.evaluate(
      manifest: manifest(),
      integrationPassed: true,
      securityPassed: true,
      backupRestorePassed: true,
      migrationPassed: true,
      paidAiGatePassed: false,
      localAiReleaseCheckPassed: true,
      tabletSmokePassed: true,
    );

    expect(result.ready, isFalse);
    expect(result.blockers.any((item) => item.contains('Ücretli AI')), isTrue);
  });

  test('imzasız production paketi yayınlanamaz', () {
    final result = service.evaluate(
      manifest: manifest(signed: false),
      integrationPassed: true,
      securityPassed: true,
      backupRestorePassed: true,
      migrationPassed: true,
      paidAiGatePassed: true,
      localAiReleaseCheckPassed: true,
      tabletSmokePassed: true,
    );

    expect(result.ready, isFalse);
  });
}
