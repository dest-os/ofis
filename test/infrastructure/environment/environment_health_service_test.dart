import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/infrastructure/environment/environment_health_service_impl.dart';

void main() {
  test('eksik yerel AI yapılandırması hazır görünmez', () async {
    final service = const DefaultEnvironmentHealthService(localBaseUrl: '', localModel: 'qwen3:4b', freeApiKey: null);
    final health = await service.check();
    expect(health.localAi.ready, isFalse);
    expect(health.localAi.message, contains('Endpoint'));
  });
}
