enum DepartmentType {
  researchIntelligence,
  softwareTechnology,
  dataAnalytics,
  designUx,
  contentDocumentation,
  securityQuality,
  operationsPlanning,
  aiEcosystem,
}

class Department {
  final String id;
  final String name;
  final DepartmentType type;
  final String description;
  final bool active;

  const Department({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.active = true,
  });

  Department copyWith({
    String? name,
    String? description,
    bool? active,
  }) {
    return Department(
      id: id,
      name: name ?? this.name,
      type: type,
      description: description ?? this.description,
      active: active ?? this.active,
    );
  }
}
