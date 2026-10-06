import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API anahtarlarını işletim sisteminin güvenli kimlik bilgisi deposunda tutar.
/// Anahtarın kendisi normal ayar dosyasına, loglara veya arşive yazılmaz.
abstract interface class SecureCredentialStore {
  Future<void> writeApiKey({required String providerId, required String value});
  Future<String?> readApiKey({required String providerId});
  Future<void> deleteApiKey({required String providerId});
}

class FlutterSecureCredentialStore implements SecureCredentialStore {
  FlutterSecureCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;

  static String _key(String providerId) => 'ares.api_key.$providerId';

  @override
  Future<void> writeApiKey({
    required String providerId,
    required String value,
  }) async {
    await _storage.write(
      key: _key(providerId),
      value: value,
    );
  }

  @override
  Future<String?> readApiKey({required String providerId}) {
    return _storage.read(key: _key(providerId));
  }

  @override
  Future<void> deleteApiKey({required String providerId}) {
    return _storage.delete(key: _key(providerId));
  }
}

/// Testlerde gerçek cihaz deposuna ihtiyaç duymadan güvenli depo sözleşmesini
/// doğrulamak için kullanılan bellek içi uygulama.
class InMemorySecureCredentialStore implements SecureCredentialStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> writeApiKey({
    required String providerId,
    required String value,
  }) async {
    _values[providerId] = value;
  }

  @override
  Future<String?> readApiKey({required String providerId}) async {
    return _values[providerId];
  }

  @override
  Future<void> deleteApiKey({required String providerId}) async {
    _values.remove(providerId);
  }
}
