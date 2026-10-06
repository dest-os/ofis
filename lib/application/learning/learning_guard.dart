import '../../domain/learning/learning_guard_result.dart';

class LearningGuard {
  const LearningGuard();

  LearningGuardResult evaluate({required String proposedChange}) {
    final text = proposedChange.toLowerCase();
    const protectedTerms = <String>[
      'permission',
      'security',
      'paid ai',
      'credential',
      'approval gate',
      'cost policy',
    ];
    final protectedChange = protectedTerms.any(text.contains);
    if (protectedChange) {
      return const LearningGuardResult(
        allowed: false,
        requiresReview: true,
        reason: 'Öğrenme sistemi güvenlik, izin, kimlik bilgisi veya ücretli AI kurallarını değiştiremez.',
      );
    }
    return const LearningGuardResult(
      allowed: true,
      requiresReview: false,
      reason: 'Öneri öğrenme kapsamı içinde değerlendirilebilir.',
    );
  }
}
