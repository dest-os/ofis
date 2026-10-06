/// Architecture strategies supported by the code generation engine.
enum ArchitectureType {
  /// Layered Clean Architecture with explicit domain/application boundaries.
  clean,

  /// A lightweight architecture for small projects.
  simple,

  /// A feature-first architecture that groups code by product capability.
  featureFirst,
}
