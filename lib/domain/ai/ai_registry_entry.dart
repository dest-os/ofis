/// Minimal immutable registry entry shared by AI catalogue views.
class AiRegistryEntry {
  /// Creates an AI registry entry.
  const AiRegistryEntry({
    required this.id,
    required this.name,
    required this.provider,
    this.model,
    this.description = '',
  });

  /// Stable registry identifier.
  final String id;

  /// Display name.
  final String name;

  /// Provider name.
  final String provider;

  /// Optional model identifier.
  final String? model;

  /// Human-readable description.
  final String description;
}
