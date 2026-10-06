import '../../domain/release/release_gate.dart';
import '../../domain/release/release_gate_status.dart';
import '../../domain/release/release_manifest.dart';
import '../../domain/release/release_result.dart';

class ProductionReleaseService {
  const ProductionReleaseService();

  ReleaseResult evaluate({
    required ReleaseManifest manifest,
    required bool integrationPassed,
    required bool securityPassed,
    required bool backupRestorePassed,
    required bool migrationPassed,
    required bool paidAiGatePassed,
    required bool localAiReleaseCheckPassed,
    required bool tabletSmokePassed,
  }) {
    final gates = <ReleaseGate>[];
    void add(String id, String title, bool passed, String message) {
      gates.add(ReleaseGate(
        id: id,
        title: title,
        required: true,
        status: passed ? ReleaseGateStatus.passed : ReleaseGateStatus.blocked,
        message: message,
      ));
    }

    add('manifest', 'Release manifest', manifest.version.trim().isNotEmpty && manifest.buildNumber.trim().isNotEmpty && manifest.integrityHash.trim().isNotEmpty, 'Sürüm, build ve bütünlük bilgileri bulunmalıdır.');
    add('signature', 'İmzalı release', manifest.signed, 'Production paketi imzalı olmalıdır.');
    add('integration', 'Entegrasyon', integrationPassed, 'V30 entegrasyon kontrolleri geçmelidir.');
    add('security', 'Güvenlik', securityPassed, 'Production güvenlik kontrolleri geçmelidir.');
    add('backup', 'Backup / Restore', backupRestorePassed, 'Yedekleme ve geri yükleme kontrolleri geçmelidir.');
    add('migration', 'Migration', migrationPassed, 'Migration kontrolleri geçmelidir.');
    add('paid_ai_gate', 'Ücretli AI son kapısı', paidAiGatePassed, 'Ücretli AI onay kapısı geçilmelidir.');
    add('local_ai', 'Local AI release kontrolü', localAiReleaseCheckPassed, 'Local AI model/lisans kontrolü geçmelidir.');
    add('tablet_smoke', '2400×1600 tablet smoke testi', tabletSmokePassed, 'Hedef tablet smoke testi geçmelidir.');

    final blockers = gates.where((gate) => !gate.passed).map((gate) => '${gate.title}: ${gate.message}').toList();
    return ReleaseResult(ready: blockers.isEmpty, gates: gates, blockers: blockers);
  }
}
