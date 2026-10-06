import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/agent_runtime/agent_decision_loop.dart';
import 'package:dest_os_ares/application/agent_runtime/agent_execution_service.dart';
import 'package:dest_os_ares/application/agent_runtime/context_builder.dart';
import 'package:dest_os_ares/application/ai/ai_gateway_service.dart';
import 'package:dest_os_ares/application/ai/ai_request_router.dart';
import 'package:dest_os_ares/application/runtime/local_ai_runtime.dart';
import 'package:dest_os_ares/domain/agent_runtime/agent_execution_contract.dart';
import 'package:dest_os_ares/domain/runtime/runtime_result.dart';

class _LocalRuntime implements LocalAiRuntime {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<RuntimeResult> run(request) async => const RuntimeResult(
        status: RuntimeResultStatus.success,
        output: 'ok',
      );
}

void main() {
  test('agent execution completes through local AI path', () async {
    final service = AgentExecutionService(
      contextBuilder: const AgentContextBuilder(),
      decisionLoop: const SafeAgentDecisionLoop(),
      aiGateway: AiGatewayService(
        router: const PolicyFirstAiRequestRouter(),
        localRuntime: _LocalRuntime(),
      ),
    );

    final result = await service.run(
      contract: const AgentExecutionContract(
        taskId: 'task-1',
        runId: 'run-1',
        instruction: 'Test görevi',
      ),
      agentId: 'agent-1',
    );

    expect(result.status, RuntimeResultStatus.success);
  });
}
