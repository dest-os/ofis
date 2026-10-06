import '../../domain/tools/tool_decision.dart';
import '../../domain/tools/tool_request.dart';

abstract interface class ToolGateway {
  Future<ToolDecision> authorize(ToolRequest request);
}
