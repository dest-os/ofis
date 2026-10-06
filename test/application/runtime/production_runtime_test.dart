import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/runtime/production/paid_ai_runtime_gate.dart';
import 'package:dest_os_ares/application/runtime/production/production_composition_root.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';

void main() {
  test('üretim runtime başlatılabilir', () async {
    final runtime = ProductionCompositionRoot().build();
    await runtime.start();

    expect(runtime.isHealthy, isTrue);
    expect(runtime.snapshot().activeTasks, 0);

    await runtime.stop();
  });

  test('ücretli AI onaysız çalıştırılamaz', () {
    const gate = PaidAiRuntimeGate();

    expect(
      gate.status(AiCostClass.paid, userApproved: false),
      'WAITING_APPROVAL',
    );
    expect(
      gate.status(AiCostClass.paid, userApproved: true),
      'READY',
    );
    expect(
      gate.status(AiCostClass.unknown, userApproved: false),
      'WAITING_APPROVAL',
    );
  });
}
