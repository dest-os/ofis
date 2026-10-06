import '../agents/agent_capability.dart';

enum CeoIntentType {
  answer,
  informationRequest,
  createTask,
  planProject,
  codeGeneration,
  continueWork,
  reviewWork,
  stopWork,
  unknown,
}

class CeoIntent {
  const CeoIntent({
    required this.type,
    required this.rawText,
    this.goal,
    this.priority = 'normal',
    this.requiredCapabilities = const <AgentCapability>[],
  });

  final CeoIntentType type;
  final String rawText;
  final String? goal;
  final String priority;
  final List<AgentCapability> requiredCapabilities;
}
