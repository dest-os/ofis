import '../agents/agent_capability.dart';
import '../tasks/task_priority.dart';

class TaskDefinition {
  const TaskDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.requiredSkills = const <String>[],
    this.requiredCapabilities = const <AgentCapability>[],
    this.requiresApproval = false,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final List<String> requiredSkills;
  final List<AgentCapability> requiredCapabilities;
  final bool requiresApproval;
}
