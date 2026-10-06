enum AiRadarCandidateType { local, free, limited }

class AiRadarCandidate {
  const AiRadarCandidate({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.configurationHint,
    this.model,
    this.address,
  });

  final String id;
  final String name;
  final AiRadarCandidateType type;
  final String description;
  final String configurationHint;
  final String? model;
  final String? address;

  String get typeLabel {
    switch (type) {
      case AiRadarCandidateType.local:
        return 'Yerel';
      case AiRadarCandidateType.free:
        return 'Ücretsiz';
      case AiRadarCandidateType.limited:
        return 'Sınırlı ücretsiz';
    }
  }

  bool get isPaid => false;
}
