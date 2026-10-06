import '../../../domain/ceo/planning/planning_decision.dart';

class PlanningDecisionEngine {
  const PlanningDecisionEngine();

  PlanningDecision choose({
    required bool archiveHit,
    required bool localAiAvailable,
    required bool freeAiAvailable,
    required bool paidAiRequired,
    required bool paidAiApproved,
  }) {
    if (archiveHit) {
      return const PlanningDecision(
        type: PlanningDecisionType.useArchive,
        reason: 'Geçerli arşiv sonucu bulundu; önce yeniden kullanılmalı.',
      );
    }
    if (localAiAvailable) {
      return const PlanningDecision(
        type: PlanningDecisionType.useLocalAi,
        reason: 'Yerel AI mevcut; dış maliyet oluşturmadan önce tercih edilir.',
      );
    }
    if (freeAiAvailable) {
      return const PlanningDecision(
        type: PlanningDecisionType.useFreeAi,
        reason: 'Ücretsiz AI seçeneği mevcut.',
      );
    }
    if (paidAiRequired && !paidAiApproved) {
      return const PlanningDecision(
        type: PlanningDecisionType.waitApproval,
        reason: 'Ücretli AI gerekiyor; İbrahim onayı bekleniyor.',
      );
    }
    if (paidAiRequired && paidAiApproved) {
      return const PlanningDecision(
        type: PlanningDecisionType.proceed,
        reason: 'Ücretli AI daha önce açıkça onaylanmış.',
      );
    }
    return const PlanningDecision(
      type: PlanningDecisionType.revise,
      reason: 'Mevcut kaynaklarla güvenli plan oluşturulamadı.',
    );
  }
}
