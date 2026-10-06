class VoiceDecision {
  const VoiceDecision({required this.allowed, required this.requiresApproval, this.reason = ''});

  final bool allowed;
  final bool requiresApproval;
  final String reason;
}
