import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/testing/integration_test_harness.dart';
import 'package:dest_os_ares/application/testing/production_readiness_service.dart';

void main() {
  test('integration harness records passing checks', () {
    final harness = IntegrationTestHarness();
    final result = harness.runCheck(
      testId: 'security',
      check: () => true,
    );

    expect(result.passed, isTrue);
    expect(harness.allPassed, isTrue);
  });

  test('production readiness reports blockers', () {
    const service = ProductionReadinessService();
    final blockers = service.blockers(
      securityPassed: true,
      paidAiGatePassed: true,
      backupRestorePassed: false,
      migrationPassed: true,
      integrationPassed: true,
    );

    expect(blockers, contains('Yedekleme/geri yükleme kontrolü başarısız.'));
    expect(service.isReady(
      securityPassed: true,
      paidAiGatePassed: true,
      backupRestorePassed: false,
      migrationPassed: true,
      integrationPassed: true,
    ), isFalse);
  });
}
