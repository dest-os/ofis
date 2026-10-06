class VoiceCommand {
  const VoiceCommand({
    required this.text,
    this.requiresApproval = false,
    this.confidence = 0,
  });

  final String text;
  final bool requiresApproval;
  final double confidence;
}
