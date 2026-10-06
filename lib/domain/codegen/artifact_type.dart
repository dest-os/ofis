/// File formats that can be emitted by the code generation engine.
enum ArtifactType {
  /// Dart source code.
  dart,

  /// YAML configuration such as `pubspec.yaml`.
  yaml,

  /// Markdown documentation.
  markdown,

  /// JSON configuration or structured data.
  json,

  /// Any other supported file type.
  other,
}
