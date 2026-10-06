class EmployeeSkill {
  final String id;
  final String name;
  final double proficiency;

  const EmployeeSkill({
    required this.id,
    required this.name,
    required this.proficiency,
  }) : assert(proficiency >= 0 && proficiency <= 1);

  EmployeeSkill copyWith({double? proficiency}) {
    return EmployeeSkill(
      id: id,
      name: name,
      proficiency: proficiency ?? this.proficiency,
    );
  }
}
