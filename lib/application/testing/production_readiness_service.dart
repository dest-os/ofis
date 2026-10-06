class ProductionReadinessService {
  const ProductionReadinessService();

  List<String> blockers({
    required bool securityPassed,
    required bool paidAiGatePassed,
    required bool backupRestorePassed,
    required bool migrationPassed,
    required bool integrationPassed,
  }) {
    final blockers = <String>[];
    if (!securityPassed) blockers.add('Güvenlik kontrolleri başarısız.');
    if (!paidAiGatePassed) blockers.add('Ücretli AI güvenlik kapısı başarısız.');
    if (!backupRestorePassed) blockers.add('Yedekleme/geri yükleme kontrolü başarısız.');
    if (!migrationPassed) blockers.add('Migration kontrolü başarısız.');
    if (!integrationPassed) blockers.add('Entegrasyon kontrolleri başarısız.');
    return blockers;
  }

  bool isReady({
    required bool securityPassed,
    required bool paidAiGatePassed,
    required bool backupRestorePassed,
    required bool migrationPassed,
    required bool integrationPassed,
  }) => blockers(
        securityPassed: securityPassed,
        paidAiGatePassed: paidAiGatePassed,
        backupRestorePassed: backupRestorePassed,
        migrationPassed: migrationPassed,
        integrationPassed: integrationPassed,
      ).isEmpty;
}
