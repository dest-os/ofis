/// Kod üretiminden sonra uygulanacak değişmez kalite kapısını temsil eder.
class QualityGate {
  /// Creates an immutable quality-gate definition.
  const QualityGate({
    required this.id,
    required this.name,
    required this.description,
    required this.required,
  });

  /// Stable identifier of the quality gate.
  final String id;

  /// Human-readable gate name.
  final String name;

  /// Explanation of the gate's purpose.
  final String description;

  /// Whether the gate is mandatory.
  final bool required;

  /// Returns a copy with the supplied fields replaced.
  QualityGate copyWith({
    String? id,
    String? name,
    String? description,
    bool? required,
  }) {
    return QualityGate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      required: required ?? this.required,
    );
  }
}

/// Bir kalite kapısının değerlendirme sonucudur.
class GateResult {
  /// Creates an immutable quality-gate result.
  const GateResult({
    required this.gateId,
    required this.passed,
    required this.message,
  });

  /// Identifier of the evaluated gate.
  final String gateId;

  /// Whether the gate passed.
  final bool passed;

  /// Human-readable evaluation message.
  final String message;

  /// Returns a copy with the supplied fields replaced.
  GateResult copyWith({
    String? gateId,
    bool? passed,
    String? message,
  }) {
    return GateResult(
      gateId: gateId ?? this.gateId,
      passed: passed ?? this.passed,
      message: message ?? this.message,
    );
  }
}
