import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/ai/ai_gateway_service.dart';
import 'package:dest_os_ares/application/ai/ai_request_router.dart';
import 'package:dest_os_ares/application/runtime/local_ai_runtime.dart';
import 'package:dest_os_ares/domain/ai/ai_request.dart';
import 'package:dest_os_ares/domain/runtime/runtime_result.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';

class _LocalRuntime implements LocalAiRuntime {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<RuntimeResult> run(request) async => const RuntimeResult(
        status: RuntimeResultStatus.success,
        output: 'yerel cevap',
      );
}

void main() {
  test('local AI request is allowed', () async {
    final gateway = AiGatewayService(
      router: const PolicyFirstAiRequestRouter(),
      localRuntime: _LocalRuntime(),
    );
    final result = await gateway.execute(const AiRequest(
      instruction: 'Merhaba',
      costClass: AiCostClass.local,
    ));
    expect(result.status, RuntimeResultStatus.success);
  });
}
