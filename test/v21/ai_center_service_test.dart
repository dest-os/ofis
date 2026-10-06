import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/ai_center/ai_center_service.dart';
import 'package:dest_os_ares/domain/ai_center/ai_center_category.dart';
import 'package:dest_os_ares/domain/ai_center/ai_center_profile.dart';

void main() {
  test('yerel AI ücretli modelden önce seçilir', () {
    final service = AiCenterService();
    final result = service.select([
      const AiCenterProfile(provider: 'Paid', model: 'P', endpoint: 'x', category: AiCenterCategory.paid, capabilities: ['chat']),
      const AiCenterProfile(provider: 'Local', model: 'L', endpoint: 'local', category: AiCenterCategory.local, capabilities: ['chat']),
    ], requiredCapabilities: ['chat']);
    expect(result.profile.provider, 'Local');
    expect(result.requiresApproval, false);
  });
}
