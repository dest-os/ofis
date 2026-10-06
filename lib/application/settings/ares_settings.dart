import '../../infrastructure/storage/json_file_store.dart';
import '../security/secure_credential_store.dart';

/// Kullanıcının Ayarlar ekranında girdiği yapay zekâ bağlantı bilgileri.
/// API anahtarının kendisi bu modelin kalıcı JSON çıktısına yazılmaz.
class AresSettings {
  const AresSettings({
    this.localEnabled = false,
    this.localBaseUrl = 'http://127.0.0.1:11434',
    this.localModel = 'qwen2.5-coder:1.5b',
    this.freeBaseUrl = '',
    this.freeModel = '',
    this.freeApiKey = '',
    this.freeApiKeyStored = false,
  });

  final bool localEnabled;
  final String localBaseUrl;
  final String localModel;
  final String freeBaseUrl;
  final String freeModel;

  /// Yalnızca çalışma belleğinde bulunur; JSON ayar dosyasına yazılmaz.
  final String freeApiKey;

  /// Normal ayarlarda yalnızca anahtarın kayıtlı olup olmadığı tutulur.
  final bool freeApiKeyStored;

  bool get freeConfigured =>
      freeBaseUrl.trim().isNotEmpty && freeModel.trim().isNotEmpty;

  bool get anyConfigured => localEnabled || freeConfigured;

  AresSettings copyWith({
    bool? localEnabled,
    String? localBaseUrl,
    String? localModel,
    String? freeBaseUrl,
    String? freeModel,
    String? freeApiKey,
    bool? freeApiKeyStored,
  }) {
    return AresSettings(
      localEnabled: localEnabled ?? this.localEnabled,
      localBaseUrl: localBaseUrl ?? this.localBaseUrl,
      localModel: localModel ?? this.localModel,
      freeBaseUrl: freeBaseUrl ?? this.freeBaseUrl,
      freeModel: freeModel ?? this.freeModel,
      freeApiKey: freeApiKey ?? this.freeApiKey,
      freeApiKeyStored: freeApiKeyStored ?? this.freeApiKeyStored,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'localEnabled': localEnabled,
        'localBaseUrl': localBaseUrl,
        'localModel': localModel,
        'freeBaseUrl': freeBaseUrl,
        'freeModel': freeModel,
        'freeApiKeyStored': freeApiKeyStored,
      };

  factory AresSettings.fromJson(
    Map<String, dynamic> json, {
    AresSettings defaults = const AresSettings(),
  }) {
    String text(String key, String fallback) {
      final value = json[key];
      return value is String ? value : fallback;
    }

    final enabled = json['localEnabled'];
    final stored = json['freeApiKeyStored'];
    return AresSettings(
      localEnabled: enabled is bool ? enabled : defaults.localEnabled,
      localBaseUrl: text('localBaseUrl', defaults.localBaseUrl),
      localModel: text('localModel', defaults.localModel),
      freeBaseUrl: text('freeBaseUrl', defaults.freeBaseUrl),
      freeModel: text('freeModel', defaults.freeModel),
      freeApiKey: '',
      freeApiKeyStored: stored is bool ? stored : defaults.freeApiKeyStored,
    );
  }
}

/// Ayarları normal depodan, API anahtarını güvenli depodan yönetir.
class AresSettingsStore {
  AresSettingsStore({
    required JsonFileStore store,
    SecureCredentialStore? credentialStore,
    AresSettings defaults = const AresSettings(),
  })  : _store = store,
        _credentialStore =
            credentialStore ?? FlutterSecureCredentialStore(),
        _defaults = defaults,
        _current = defaults;

  static const String _fileName = 'ares_settings';
  static const String _freeApiProviderId = 'free_remote';

  final JsonFileStore _store;
  final SecureCredentialStore _credentialStore;
  final AresSettings _defaults;
  AresSettings _current;

  AresSettings get current => _current;

  Future<void> load() async {
    final raw = await _store.read(_fileName);
    AresSettings loaded = _defaults;
    String? legacyPlaintextKey;

    if (raw is Map) {
      final rawMap = Map<String, dynamic>.from(raw);
      final legacy = rawMap['freeApiKey'];
      if (legacy is String && legacy.trim().isNotEmpty) {
        legacyPlaintextKey = legacy.trim();
      }
      loaded = AresSettings.fromJson(rawMap, defaults: _defaults);
    }

    var secureKey = await _credentialStore.readApiKey(
      providerId: _freeApiProviderId,
    );

    // Eski sürümde anahtar yanlışlıkla normal JSON'a yazılmışsa bir kez
    // güvenli depoya taşınır ve hemen ardından normal ayar dosyası temizlenir.
    if ((secureKey == null || secureKey.isEmpty) &&
        legacyPlaintextKey != null) {
      await _credentialStore.writeApiKey(
        providerId: _freeApiProviderId,
        value: legacyPlaintextKey,
      );
      secureKey = legacyPlaintextKey;
    }

    _current = loaded.copyWith(
      freeApiKey: secureKey ?? '',
      freeApiKeyStored: secureKey != null && secureKey.isNotEmpty,
    );

    // Normal ayar dosyasında eski plaintext anahtar kalmış olmasın.
    await _store.write(_fileName, _current.toJson());
  }

  /// Normal ayarları kaydeder. [apiKey] verilirse güvenli depoya yazılır.
  /// Boş bırakılırsa mevcut güvenli anahtar korunur.
  Future<void> save(
    AresSettings settings, {
    String? apiKey,
    bool clearApiKey = false,
  }) async {
    final candidate = apiKey?.trim();

    if (clearApiKey) {
      await _credentialStore.deleteApiKey(providerId: _freeApiProviderId);
    } else if (candidate != null && candidate.isNotEmpty) {
      await _credentialStore.writeApiKey(
        providerId: _freeApiProviderId,
        value: candidate,
      );
    }

    final storedKey = clearApiKey
        ? null
        : (candidate != null && candidate.isNotEmpty
            ? candidate
            : await _credentialStore.readApiKey(
                providerId: _freeApiProviderId,
              ));

    _current = settings.copyWith(
      freeApiKey: storedKey ?? '',
      freeApiKeyStored: storedKey != null && storedKey.isNotEmpty,
    );

    await _store.write(_fileName, _current.toJson());
  }
}
