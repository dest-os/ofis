enum AiCostClass {
  local,
  free,
  limitedFree,
  paid,
  unknown,
}

class CostPolicy {
  const CostPolicy._();

  static bool mayRunWithoutUserApproval(AiCostClass costClass) {
    return costClass == AiCostClass.local ||
        costClass == AiCostClass.free ||
        costClass == AiCostClass.limitedFree;
  }

  static String explanation(AiCostClass costClass) {
    switch (costClass) {
      case AiCostClass.local:
        return 'Yerel AI: doğrulanmış ücretsiz model olmalıdır.';
      case AiCostClass.free:
        return 'Ücretsiz AI.';
      case AiCostClass.limitedFree:
        return 'Sınırlı ücretsiz AI; kullanım limitleri kontrol edilmelidir.';
      case AiCostClass.paid:
        return 'Ücretli AI: İbrahim tarafından açık onay gerekir.';
      case AiCostClass.unknown:
        return 'Fiyat veya lisans bilinmiyor; ücretsiz kabul edilemez.';
    }
  }
}
