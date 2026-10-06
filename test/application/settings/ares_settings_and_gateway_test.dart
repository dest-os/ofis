import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/security/secure_credential_store.dart';
import 'package:dest_os_ares/application/settings/ares_settings.dart';
import 'package:dest_os_ares/core/result/ares_result.dart';
import 'package:dest_os_ares/core/security/cost_policy.dart';
import 'package:dest_os_ares/domain/ai/ai_request.dart';
import 'package:dest_os_ares/domain/ai/ai_response.dart';
import 'package:dest_os_ares/infrastructure/codegen/dynamic_ares_ai_gateway.dart';
import 'package:dest_os_ares/infrastructure/codegen/openai_compatible_transport.dart';
import 'package:dest_os_ares/infrastructure/storage/json_file_store.dart';

class _FakeTransport implements AiHttpTransport {
  Uri? lastUri;
  Map<String, String>? lastHeaders;

  @override
  Future<AiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    lastUri = uri;
    lastHeaders = headers;
    return const AiHttpResponse(
      statusCode: 200,
      body: '{"model":"m1","choices":[{"message":{"content":"tamam"}}]}',
    );
  }
}

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('ares_settings_'));
  tearDown(() => temp.deleteSync(recursive: true));

  AresSettingsStore store({SecureCredentialStore? credentials}) =>
      AresSettingsStore(
        store: JsonFileStore(directoryProvider: () async => temp),
        credentialStore: credentials ?? InMemorySecureCredentialStore(),
      );

  test('ayarlar yeniden açılışta anahtarı güvenli depodan okur', () async {
    final credentials = InMemorySecureCredentialStore();
    final first = store(credentials: credentials);

    await first.save(
      const AresSettings(
        freeBaseUrl: 'https://x.test/v1',
        freeModel: 'm1',
      ),
      apiKey: 'k-123456',
    );

    final jsonFile = File('${temp.path}/ares_settings.json');
    final jsonText = await jsonFile.readAsString();
    expect(jsonText, isNot(contains('k-123456')));

    final second = store(credentials: credentials);
    await second.load();

    expect(second.current.freeBaseUrl, 'https://x.test/v1');
    expect(second.current.freeModel, 'm1');
    expect(second.current.freeApiKey, 'k-123456');
    expect(second.current.freeApiKeyStored, isTrue);
  });

  test('gateway anahtarı güvenli depodan okur ve istekte kullanır', () async {
    final credentials = InMemorySecureCredentialStore();
    final s = store(credentials: credentials);

    await s.save(
      const AresSettings(
        freeBaseUrl: 'https://x.test/v1',
        freeModel: 'm1',
      ),
      apiKey: 'k-123456',
    );

    final second = store(credentials: credentials);
    await second.load();

    final transport = _FakeTransport();
    final gateway = DynamicAresAiGateway(
      settings: second,
      transport: transport,
    );
    final result = await gateway.generate(
      const AiRequest(instruction: 'selam', costClass: AiCostClass.free),
    );

    expect(result, isA<AresSuccess<AiResponse>>());
    expect(transport.lastHeaders!['Authorization'], 'Bearer k-123456');
  });

  test('ayar anahtarı kayıtlı değilse açık durum tutulur', () async {
    final s = store();
    await s.save(
      const AresSettings(
        freeBaseUrl: 'https://x.test/v1',
        freeModel: 'm1',
      ),
    );

    expect(s.current.freeApiKeyStored, isFalse);
    expect(s.current.freeApiKey, isEmpty);
  });

  test('eski plaintext anahtar bir kez güvenli depoya taşınır ve dosyadan silinir',
      () async {
    final credentials = InMemorySecureCredentialStore();
    final jsonStore = JsonFileStore(directoryProvider: () async => temp);

    await jsonStore.write('ares_settings', <String, Object?>{
      'localEnabled': false,
      'localBaseUrl': 'http://127.0.0.1:11434',
      'localModel': 'qwen2.5-coder:1.5b',
      'freeBaseUrl': 'https://x.test/v1',
      'freeModel': 'm1',
      'freeApiKey': 'legacy-secret',
    });

    final s = AresSettingsStore(
      store: jsonStore,
      credentialStore: credentials,
    );
    await s.load();

    expect(s.current.freeApiKey, 'legacy-secret');
    expect(s.current.freeApiKeyStored, isTrue);

    final jsonText =
        await File('${temp.path}/ares_settings.json').readAsString();
    expect(jsonText, isNot(contains('legacy-secret')));
    expect(
      await credentials.readApiKey(providerId: 'free_remote'),
      'legacy-secret',
    );
  });

  test('gateway hata metninde API anahtarını dışarı sızdırmaz', () async {
    final credentials = InMemorySecureCredentialStore();
    final s = store(credentials: credentials);
    await s.save(
      const AresSettings(
        freeBaseUrl: 'https://x.test/v1',
        freeModel: 'm1',
      ),
      apiKey: 'SECRET-123',
    );

    final leakingTransport = _LeakingTransport();
    final gateway = DynamicAresAiGateway(
      settings: s,
      transport: leakingTransport,
    );

    final result = await gateway.generate(
      const AiRequest(instruction: 'selam', costClass: AiCostClass.free),
    );

    expect(result, isA<AresFailure<AiResponse>>());
    expect(
      (result as AresFailure<AiResponse>).message,
      isNot(contains('SECRET-123')),
    );
  });

  test('ayar yoksa anlaşılır hata verir', () async {
    final gateway = DynamicAresAiGateway(
      settings: store(),
      transport: _FakeTransport(),
    );
    final result = await gateway.generate(
      const AiRequest(instruction: 'selam', costClass: AiCostClass.free),
    );
    expect(result, isA<AresFailure<AiResponse>>());
    expect((result as AresFailure<AiResponse>).message, contains('Ayarlar'));
  });

  test('ücretli maliyet sınıfı otomatik açılmaz', () async {
    final s = store();
    await s.save(
      const AresSettings(
        freeBaseUrl: 'https://x.test/v1',
        freeModel: 'm1',
      ),
    );
    final gateway = DynamicAresAiGateway(
      settings: s,
      transport: _FakeTransport(),
    );
    final result = await gateway.generate(
      const AiRequest(instruction: 'selam', costClass: AiCostClass.paid),
    );
    expect(result, isA<AresFailure<AiResponse>>());
  });
}

class _LeakingTransport implements AiHttpTransport {
  @override
  Future<AiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    return const AiHttpResponse(
      statusCode: 401,
      body: 'Yetkisiz istek: SECRET-123',
    );
  }
}
