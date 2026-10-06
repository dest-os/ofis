import '../../domain/agent_runtime/agent_execution_contract.dart';
import '../../domain/agent_runtime/agent_run.dart';
import '../../domain/agent_runtime/agent_run_status.dart';
import '../../domain/ai/ai_request.dart';
import '../../core/security/cost_policy.dart';
import '../../domain/runtime/runtime_result.dart';
import '../ai/ai_gateway_service.dart';
import 'agent_decision_loop.dart';
import 'context_builder.dart';
import 'structured_output_validator.dart';

class AgentExecutionService {
  const AgentExecutionService({
    required this.contextBuilder,
    required this.decisionLoop,
    required this.aiGateway,
    this.validator = const StructuredOutputValidator(),
  });

  final AgentContextBuilder contextBuilder;
  final AgentDecisionLoop decisionLoop;
  final AiGatewayService aiGateway;
  final StructuredOutputValidator validator;

  Future<RuntimeResult> run({
    required AgentExecutionContract contract,
    required String agentId,
  }) async {
    final run = AgentRun(
      runId: contract.runId,
      taskId: contract.taskId,
      agentId: agentId,
      attempt: 1,
      startedAt: DateTime.now(),
    );
    run.status = AgentRunStatus.contextReady;
    final context = contextBuilder.build(contract: contract, agentId: agentId);
    run.status = AgentRunStatus.deciding;
    final decision = await decisionLoop.decide(context);
    if (decision.requiresApproval) {
      run.status = AgentRunStatus.waitingApproval;
      return const RuntimeResult(
        status: RuntimeResultStatus.waitingApproval,
        error: 'Agent kararı için onay gerekiyor.',
      );
    }
    run.status = AgentRunStatus.executing;
    final result = await aiGateway.execute(
      _toAiRequest(contract),
    );
    if (!result.isSuccess) return result;
    final validation = validator.validate(result.output);
    if (!validation.valid) {
      run.status = AgentRunStatus.failed;
      return RuntimeResult(
        status: RuntimeResultStatus.failed,
        error: validation.error,
      );
    }
    run.status = AgentRunStatus.completed;
    run.completedAt = DateTime.now();
    return result;
  }

  dynamic _toAiRequest(AgentExecutionContract contract) {
    // AI isteği gerçek adapter tarafından V18 sonrası bağlanacaktır.
    return AiRequest(
      instruction: contract.instruction,
      costClass: AiCostClass.local,
    );
  }
}

