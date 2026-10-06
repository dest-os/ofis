class AiCapabilityProfile {
  const AiCapabilityProfile({
    this.text = true,
    this.vision = false,
    this.tools = false,
    this.structuredOutput = false,
  });

  final bool text;
  final bool vision;
  final bool tools;
  final bool structuredOutput;
}
