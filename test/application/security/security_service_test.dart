import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/security/security_service.dart';
import 'package:dest_os_ares/domain/ai/ai_category.dart';
import 'package:dest_os_ares/domain/security/permission_level.dart';
import 'package:dest_os_ares/domain/security/risk_level.dart';
import 'package:dest_os_ares/domain/security/security_principal.dart';
import 'package:dest_os_ares/domain/security/security_scope.dart';

void main() {
  final founder = SecurityPrincipal(id: 'ibrahim', name: 'İbrahim', level: PermissionLevel.admin, scope: const SecurityScope(userId: 'ibrahim'), isFounder: true);
  final agent = SecurityPrincipal(id: 'agent', name: 'Agent', level: PermissionLevel.execute, scope: const SecurityScope(userId: 'ibrahim'));

  test('yüksek risk onay ister', () {
    final service = SecurityService();
    final result = service.authorizeAction(principal: agent, requiredLevel: PermissionLevel.execute, riskLevel: RiskLevel.high, reason: 'kritik işlem');
    expect(result.type.toString(), contains('requireApproval'));
  });

  test('yetkisiz yönetim işlemi reddedilir', () {
    final service = SecurityService();
    final result = service.authorizeAction(principal: agent, requiredLevel: PermissionLevel.admin, riskLevel: RiskLevel.low, reason: 'yönetim');
    expect(result.allowed, isFalse);
  });

  test('ücretli AI doğrudan çalıştırılmaz', () {
    final service = SecurityService();
    final result = service.authorizeAi(principal: founder, category: AiCategory.paid);
    expect(result.type.toString(), contains('requireApproval'));
  });
}
