import 'architecture_type.dart';

/// Kod üretim motorunun üreteceği projenin değişmez tanımıdır.
class ProjectSpec {
  /// Creates an immutable project specification.
  ProjectSpec({
    required this.projectName,
    required this.description,
    required this.packageName,
    required this.features,
    required this.architecture,
    required this.requiredPackages,
    required this.screens,
    required this.acceptanceCriteria,
    required this.includeTests,
    required this.includeReadme,
  }) : features = List.unmodifiable(features),
       requiredPackages = List.unmodifiable(requiredPackages),
       screens = List.unmodifiable(screens),
       acceptanceCriteria = List.unmodifiable(acceptanceCriteria);

  /// Display name of the project.
  final String projectName;

  /// High-level description of the requested project.
  final String description;

  /// Dart/Flutter package name.
  final String packageName;

  /// Requested product capabilities.
  final List<String> features;

  /// Architecture strategy to use.
  final ArchitectureType architecture;

  /// Additional packages required by the generated project.
  final List<String> requiredPackages;

  /// Requested screens or presentation surfaces.
  final List<String> screens;

  /// Conditions used to judge whether generation is complete.
  final List<String> acceptanceCriteria;

  /// Whether tests should be included in the generated project.
  final bool includeTests;

  /// Whether project documentation should be included.
  final bool includeReadme;

  /// Returns a copy with the supplied fields replaced.
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
