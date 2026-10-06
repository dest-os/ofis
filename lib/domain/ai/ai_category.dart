enum AiCategory {
  local,
  free,
  limitedFree,
  paid,
  unknown,
}

extension AiCategoryLabel on AiCategory {
  String get label {
    switch (this) {
      case AiCategory.local:
        return 'LOCAL';
      case AiCategory.free:
        return 'FREE';
      case AiCategory.limitedFree:
        return 'LIMITED_FREE';
      case AiCategory.paid:
        return 'PAID';
      case AiCategory.unknown:
        return 'UNKNOWN';
    }
  }
}
