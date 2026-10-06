import '../agents/agent_capability.dart';
import 'task_priority.dart';

class TaskContract {
  const TaskContract({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.acceptanceCriteria,
    this.requiredSkills = const <String>[],
    this.requiredCapabilities = const <AgentCapability>[],
    this.inputs = const <String>[],
    this.outputs = const <String>[],
    this.constraints = const <String>[],
    this.requiresReview = true,
    this.requiresApproval = false,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final List<String> acceptanceCriteria;
  final List<String> requiredSkills;
  final List<AgentCapability> requiredCapabilities;
  final List<String> inputs;
  final List<String> outputs;
  final List<String> constraints;
  final bool requiresReview;
  final bool requiresApproval;
}
