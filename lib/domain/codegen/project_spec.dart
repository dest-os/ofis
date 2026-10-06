import 'architecture_type.dart';

/// Kod üretim motorunun üreteceği projenin değişmez tanımıdır.
class ProjectSpec {
  ProjectSpec({
    required this.projectName,
    required this.description,
    required this.packageName,
    required List<String> features,
    required this.architecture,
    required List<String> requiredPackages,
    required List<String> screens,
    required List<String> acceptanceCriteria,
    required this.includeTests,
    required this.includeReadme,
  })  : features = List.unmodifiable(features),
        requiredPackages = List.unmodifiable(requiredPackages),
        screens = List.unmodifiable(screens),
        acceptanceCriteria = List.unmodifiable(acceptanceCriteria);

  final String projectName;
  final String description;
  final String packageName;
  final List<String> features;
  final ArchitectureType architecture;
  final List<String> requiredPackages;
  final List<String> screens;
  final List<String> acceptanceCriteria;
  final bool includeTests;
  final bool includeReadme;

  ProjectSpec copyWith({
    String? projectName,
    String? description,
    String? packageName,
    List<String>? features,
    ArchitectureType? architecture,
    List<String>? requiredPackages,
    List<String>? screens,
    List<String>? acceptanceCriteria,
    bool? includeTests,
    bool? includeReadme,
  }) {
    return ProjectSpec(
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      packageName: packageName ?? this.packageName,
      features: features ?? this.features,
      architecture: architecture ?? this.architecture,
      requiredPackages: requiredPackages ?? this.requiredPackages,
      screens: screens ?? this.screens,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      includeTests: includeTests ?? this.includeTests,
      includeReadme: includeReadme ?? this.includeReadme,
    );
  }
}
