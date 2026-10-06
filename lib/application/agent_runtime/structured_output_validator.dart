class StructuredOutputValidationResult {
  const StructuredOutputValidationResult({
    required this.valid,
    this.error,
  });

  final bool valid;
  final String? error;
}

class StructuredOutputValidator {
  const StructuredOutputValidator();

  StructuredOutputValidationResult validate(Object? output) {
    if (output == null) {
      return const StructuredOutputValidationResult(
        valid: false,
        error: 'AI çıktısı boş.',
      );
    }
    return const StructuredOutputValidationResult(valid: true);
  }
}
