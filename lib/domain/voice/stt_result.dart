class SttResult {
  const SttResult({required this.text, required this.confidence, this.isFinal = true});

  final String text;
  final double confidence;
  final bool isFinal;
}
