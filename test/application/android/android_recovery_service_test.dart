import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/android/android_recovery_service.dart';

void main() {
  test('interrupted runtime requires recovery until recovered', () {
    final service = AndroidRecoveryService();
    expect(service.recoveryRequired, false);
    service.markInterrupted();
    expect(service.recoveryRequired, true);
    service.markRecovered();
    expect(service.recoveryRequired, false);
  });
}
