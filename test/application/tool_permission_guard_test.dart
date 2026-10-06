import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/tools/tool_permission_guard.dart';
import 'package:dest_os_ares/domain/tools/tool_definition.dart';
import 'package:dest_os_ares/domain/tools/tool_kind.dart';
import 'package:dest_os_ares/domain/tools/tool_request.dart';
import 'package:dest_os_ares/domain/tools/tool_risk_level.dart';
import 'package:dest_os_ares/domain/tools/tool_decision.dart';

void main() {
  test('yüksek riskli araç onaysız çalıştırılamaz', () {
    const definition = ToolDefinition(
      id: 'high-risk',
      name: 'High Risk',
      description: 'Test',
      kind: ToolKind.restApi,
      riskLevel: ToolRiskLevel.high,
    );

    final request = ToolRequest(
      id: 'request-1',
      toolId: 'high-risk',
      action: 'write',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final result = ToolPermissionGuard().evaluate(
      definition: definition,
      request: request,
      userApproved: false,
    );

    expect(result.type, ToolDecisionType.requireApproval);
  });
}
