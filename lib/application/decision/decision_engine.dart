import '../../domain/decision/decision.dart';
import '../../domain/decision/decision_type.dart';

class DecisionEngine {
  Decision decide({
    required String id,
    required bool archiveAvailable,
    required bool localAiAvailable,
    required bool freeAiAvailable,
    required bool paidAiAvailable,
  }) {
    if (archiveAvailable) {
      return Decision(
        id: id,
        type: DecisionType.useArchive,
        reason: 'Geçerli arşiv bulunduğu için önce arşiv kullanılmalı.',
        createdAt: DateTime.now().toUtc(),
      );
    }

    if (localAiAvailable) {
      return Decision(
        id: id,
        type: DecisionType.useLocalAi,
        reason: 'Yerel AI mevcut ve maliyet oluşturmuyor.',
        createdAt: DateTime.now().toUtc(),
      );
    }

    if (freeAiAvailable) {
      return Decision(
        id: id,
        type: DecisionType.useFreeAi,
        reason: 'Ücretsiz AI seçeneği mevcut.',
        createdAt: DateTime.now().toUtc(),
      );
    }

    if (paidAiAvailable) {
      return Decision(
        id: id,
        type: DecisionType.requireApproval,
        reason: 'Ücretli AI kullanılmadan önce İbrahim onayı gerekiyor.',
        createdAt: DateTime.now().toUtc(),
        requiresUserApproval: true,
        alternatives: const <String>[
          'Yerel AI ara',
          'Ücretsiz AI ara',
          'Sınırlı ücretsiz AI ara',
        ],
      );
    }

    return Decision(
      id: id,
      type: DecisionType.defer,
      reason: 'Uygun AI kaynağı bulunamadı; görev beklemeye alınmalı.',
      createdAt: DateTime.now().toUtc(),
    );
  }
}
