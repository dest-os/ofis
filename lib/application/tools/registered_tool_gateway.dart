import '../../domain/tools/tool_decision.dart';
import '../../domain/tools/tool_request.dart';
import 'tool_gateway.dart';
import 'tool_permission_guard.dart';
import 'tool_registry.dart';

class RegisteredToolGateway implements ToolGateway {
  RegisteredToolGateway({
    required ToolRegistry registry,
    ToolPermissionGuard? guard,
  })  : _registry = registry,
        _guard = guard ?? ToolPermissionGuard();

  final ToolRegistry _registry;
  final ToolPermissionGuard _guard;

  @override
  Future<ToolDecision> authorize(ToolRequest request) async {
    final definition = await _registry.getById(request.toolId);

    if (definition == null) {
      return const ToolDecision(
        type: ToolDecisionType.deny,
        reason: 'Araç kayıtlı değil.',
      );
    }

    final approved =
        request.parameters['user_approved'] == true;

    return _guard.evaluate(
      definition: definition,
      request: request,
      userApproved: approved,
    );
  }
}
