import '../agents/agent_capability.dart';
import '../tasks/task_priority.dart';

class CeoPlan {
  const CeoPlan({
    required this.id,
    required this.goal,
    required this.taskIds,
    required this.priority,
    required this.createdAt,
    this.requiredCapabilities = const <AgentCapability>[],
    this.requiresApproval = false,
  });

  final String id;
  final String goal;
  final List<String> taskIds;
  final TaskPriority priority;
  final DateTime createdAt;
  final List<AgentCapability> requiredCapabilities;
  final bool requiresApproval;
}
