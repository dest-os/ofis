import 'package:flutter_test/flutter_test.dart';
import 'package:ares/application/ceo/planning/planning_decision_engine.dart';
import 'package:ares/domain/ceo/planning/planning_decision.dart';

void main() {
  test('arşiv sonucu diğer kaynaklardan önce seçilir', () {
    final decision = const PlanningDecisionEngine().choose(
      archiveHit: true,
      localAiAvailable: true,
      freeAiAvailable: true,
      paidAiRequired: true,
      paidAiApproved: false,
    );
    expect(decision.type, PlanningDecisionType.useArchive);
  });

  test('onaysız ücretli AI beklemeye alınır', () {
    final decision = const PlanningDecisionEngine().choose(
      archiveHit: false,
      localAiAvailable: false,
      freeAiAvailable: false,
      paidAiRequired: true,
      paidAiApproved: false,
    );
    expect(decision.type, PlanningDecisionType.waitApproval);
  });
}
