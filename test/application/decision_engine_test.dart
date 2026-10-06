import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/decision/decision_engine.dart';
import 'package:dest_os_ares/domain/decision/decision_type.dart';

void main() {
  test('arşiv varsa önce arşiv seçilir', () {
    final engine = DecisionEngine();

    final decision = engine.decide(
      id: 'decision-1',
      archiveAvailable: true,
      localAiAvailable: true,
      freeAiAvailable: true,
      paidAiAvailable: true,
    );

    expect(decision.type, DecisionType.useArchive);
    expect(decision.requiresUserApproval, isFalse);
  });

  test('ücretli AI son seçenekse onay gerekir', () {
    final engine = DecisionEngine();

    final decision = engine.decide(
      id: 'decision-2',
      archiveAvailable: false,
      localAiAvailable: false,
      freeAiAvailable: false,
      paidAiAvailable: true,
    );

    expect(decision.type, DecisionType.requireApproval);
    expect(decision.requiresUserApproval, isTrue);
  });
}
