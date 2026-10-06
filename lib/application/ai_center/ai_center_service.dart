import '../../domain/ai_center/ai_center_category.dart';
import '../../domain/ai_center/ai_center_profile.dart';
import '../../domain/ai_center/ai_center_selection.dart';

class AiCenterService {
  AiCenterSelection select(List<AiCenterProfile> profiles, {required List<String> requiredCapabilities}) {
    final candidates = profiles.where((p) => requiredCapabilities.every(p.capabilities.contains)).toList();
    if (candidates.isEmpty) {
      throw StateError('Uygun AI modeli bulunamadı.');
    }
    candidates.sort((a, b) => _score(b).compareTo(_score(a)));
    final selected = candidates.first;
    return AiCenterSelection(
      profile: selected,
      requiresApproval: selected.requiresApproval,
      reason: selected.requiresApproval ? 'Bu AI modeli için İbrahim onayı gerekir.' : 'Model güvenli kategori içinde seçildi.',
    );
  }

  int _score(AiCenterProfile p) {
    switch (p.category) {
      case AiCenterCategory.local: return 5;
      case AiCenterCategory.free: return 4;
      case AiCenterCategory.limitedFree: return 3;
      case AiCenterCategory.paid: return 2;
      case AiCenterCategory.unknown: return 1;
    }
  }
}
