import '../../domain/codegen/architecture_type.dart';
import '../../domain/codegen/project_spec.dart';

/// Converts a high-level user request into a deterministic [ProjectSpec].
///
/// This service never calls an AI provider. It performs local normalization,
/// feature/screen inference and safe package-name generation before the AI
/// agents receive the resulting specification.
class ProjectSpecFromRequest {
  /// Creates the request-to-spec converter.
  const ProjectSpecFromRequest();

  /// Builds a consistent project specification from [request].
  ProjectSpec build(String request) {
    final text = request.trim();
    if (text.length < 5 || text.split(RegExp(r'\s+')).length < 2) {
      throw ArgumentError.value(
        request,
        'request',
        'İstek çok kısa. Üretilecek uygulamayı ve temel amacını açıkça yazın.',
      );
    }

    final lower = text.toLowerCase();
    final projectName = _projectName(text);
    final packageName = _packageName(projectName);
    final features = <String>[];
    final screens = <String>[];
    final packages = <String>[];

    void addFeature(String feature) => _addUnique(features, feature);
    void addScreen(String screen) => _addUnique(screens, screen);
    void addPackage(String packageName) => _addUnique(packages, packageName);

    if (_containsAny(lower, const ['counter', 'sayaç'])) {
      addFeature('Sayaç değerini artırma ve azaltma');
      addScreen('Counter');
    }
    if (_containsAny(lower, const ['görev', 'task', 'todo', 'yapılacak'])) {
      addFeature('Görev ekleme, listeleme ve tamamlanma durumu');
      addScreen('Görevler');
      addPackage('shared_preferences');
    }
    if (_containsAny(lower, const ['finans', 'bütçe', 'harcama', 'gelir', 'gider'])) {
      addFeature('Gelir ve gider kayıtları');
      addFeature('Bakiye ve özet görünümü');
      addScreen('Finans Özeti');
      addScreen('İşlemler');
      addPackage('intl');
      addPackage('shared_preferences');
    }
    if (_containsAny(lower, const ['chat', 'sohbet', 'mesaj', 'mesajlaşma'])) {
      addFeature('Mesaj gönderme ve konuşma geçmişi');
      addScreen('Sohbet');
    }
    if (_containsAny(lower, const ['ayar', 'settings', 'profil'])) {
      addFeature('Uygulama ayarları ve kullanıcı tercihleri');
      addScreen('Ayarlar');
    }
    if (_containsAny(lower, const ['hava', 'weather', 'konum', 'harita', 'map'])) {
      addFeature('Konum veya dış veri gösterimi');
      addScreen('Bilgi / Harita');
      addPackage('http');
    }
    if (_containsAny(lower, const ['giriş', 'login', 'oturum', 'kullanıcı'])) {
      addFeature('Kullanıcı giriş ve oturum akışı');
      addScreen('Giriş');
    }
    if (_containsAny(lower, const ['liste', 'catalog', 'katalog', 'ürün'])) {
      addFeature('Listeleme ve detay görüntüleme');
      addScreen('Liste');
      addScreen('Detay');
    }
    if (_containsAny(lower, const ['not', 'note'])) {
      addFeature('Not oluşturma ve düzenleme');
      addScreen('Notlar');
      addPackage('shared_preferences');
    }

    if (features.isEmpty) {
      addFeature('Kullanıcının yüksek seviyeli isteğinin temel iş akışı');
    }
    if (screens.isEmpty) {
      addScreen('Ana Ekran');
    }

    return ProjectSpec(
      projectName: projectName,
      description: text,
      packageName: packageName,
      features: features,
      architecture: ArchitectureType.clean,
      requiredPackages: packages,
      screens: screens,
      acceptanceCriteria: <String>[
        'main.dart ve pubspec.yaml oluşturulmalı',
        'Derlenebilir bir Flutter proje iskeleti oluşturulmalı',
        'Temel ekran veya ekranlar oluşturulmalı',
        'Domain, application ve presentation katmanlarında tutarlı kod bulunmalı',
        'Kritik importlar ve temel yapı doğrulama kontrolünden geçmeli',
      ],
      includeTests: true,
      includeReadme: true,
    );
  }

  String _projectName(String request) {
    final cleaned = request
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(r'^(basit bir|bir|basit|kişisel)\s+', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'\s+(üret|oluştur|yap|hazırla|geliştir|create|build|make)\.?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    final source = cleaned.isEmpty ? 'Üretilen Uygulama' : cleaned;
    final words = source.split(' ').where((word) => word.isNotEmpty).take(6);
    final title = words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return 'ARES $title';
  }

  String _packageName(String projectName) {
    final value = projectName
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = value.isEmpty ? 'ares_generated_app' : value;
    return RegExp(r'^[0-9]').hasMatch(safe) ? 'ares_generated_app' : safe;
  }

  bool _containsAny(String value, List<String> keywords) =>
      keywords.any(value.contains);

  void _addUnique(List<String> values, String value) {
    if (!values.contains(value)) values.add(value);
  }
}
