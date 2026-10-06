enum AgentCapability {
  research,
  planning,
  coding,
  codeGeneration,
  analysis,
  design,
  documentation,
  testing,
  security,
  recovery,
  monitoring,
  communication,
}

extension AgentCapabilityX on AgentCapability {
  String get value => name.toUpperCase();
}
