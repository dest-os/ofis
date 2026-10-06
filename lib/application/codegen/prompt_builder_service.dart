import '../../domain/codegen/project_spec.dart';

/// Kod üretiminde kullanılabilecek ajan rolleri.
enum CodegenAgentRole {
  /// Clarifies the product request and acceptance criteria.
  productManager,

  /// Defines architecture and boundaries.
  architect,

  /// Produces Flutter/Dart implementation code.
  flutterDeveloper,

  /// Focuses on tests and acceptance criteria.
  qaEngineer,

  /// Produces build, CI/CD, and deployment artifacts.
  devOps,
}

extension CodegenAgentRoleLabel on CodegenAgentRole {
  /// Human-readable name used in prompts and artifact metadata.
  String get displayName {
    switch (this) {
      case CodegenAgentRole.productManager:
        return 'ProductManager';
      case CodegenAgentRole.architect:
        return 'Architect';
      case CodegenAgentRole.flutterDeveloper:
        return 'FlutterDeveloper';
      case CodegenAgentRole.qaEngineer:
        return 'QAEngineer';
      case CodegenAgentRole.devOps:
        return 'DevOps';
    }
  }
}

/// LLM'e gönderilecek sistem ve kullanıcı promptlarını birlikte taşır.
class CodegenPrompt {
  /// Creates a structured prompt for a code-generation agent.
  const CodegenPrompt({
    required this.role,
    required this.systemPrompt,
    required this.userPrompt,
  });

  /// Agent role receiving the prompt.
  final CodegenAgentRole role;

  /// System-level instructions for the agent.
  final String systemPrompt;

  /// User-level task and context instructions.
  final String userPrompt;
}

/// Her ajan rolü için güvenli ve sınırlı bağlam oluşturan prompt üreticisidir.
class PromptBuilderService {
  /// Creates a prompt builder.
  const PromptBuilderService();

  /// Builds a role-specific prompt from the project specification and file list.
  CodegenPrompt build({
    required CodegenAgentRole role,
    required ProjectSpec projectSpec,
    required List<String> relevantFiles,
    Map<String, String> fileExcerpts = const <String, String>{},
  }) {
    final roleName = role.displayName;
    final context = _buildContext(
      projectSpec: projectSpec,
      relevantFiles: relevantFiles,
      fileExcerpts: fileExcerpts,
    );

    return CodegenPrompt(
      role: role,
      systemPrompt: _systemPrompt(roleName),
      userPrompt: _userPrompt(
        roleName: roleName,
        context: context,
      ),
    );
  }

  String _systemPrompt(String roleName) {
    final common = '''
Sen DEST-OS ARES Kod Üretim Motoru içinde çalışan $roleName ajanısın.
Sadece sana verilen ProjectSpec ve ilgili dosya bağlamını kullan.
Bağlamda bulunmayan proje ayrıntılarını uydurma.
Ürettiğin çıktı JSON olmalı ve şu kök yapıyı kullanmalıdır:
{"artifacts":[{"relativePath":"...","content":"...","type":"dart|yaml|markdown|json|other","generatedBy":"$roleName"}]}
Her artifact gerçek bir dosyayı temsil eder. relativePath göreli olmalı ve proje kökü dışına çıkmamalıdır.
''';

    switch (roleName) {
      case 'ProductManager':
        return '$common\nİsteği netleştir, özellikleri ve kabul kriterlerini doğrula; yalnızca ürün tanımını temsil eden belgeleri üret.';
      case 'Architect':
        return '$common\nMimari sınırları, katman ayrımını, bağımlılık yönünü ve dosya sorumluluklarını koru.';
      case 'FlutterDeveloper':
        return '$common\nFlutter/Dart kodunu derlenebilir, okunabilir ve mevcut mimariye uyumlu üret.';
      case 'QAEngineer':
        return '$common\nTest edilebilirlik, acceptance criteria, hata senaryoları ve doğrulanabilir çıktılara odaklan.';
      case 'DevOps':
        return '$common\nBuild, yapılandırma, CI/CD, ortam ve dağıtım dosyalarını güvenli ve tekrarlanabilir üret.';
      default:
        return common;
    }
  }

  String _userPrompt({
    required String roleName,
    required String context,
  }) {
    return '''
Rol: $roleName

Aşağıdaki sınırlı bağlamı kullanarak görevi yerine getir.
Sadece bu bağlamdaki ProjectSpec ve ilgili dosyalarla ilişkili dosyaları üret.
Mevcut dosyaları değiştirmek gerekiyorsa tam dosya içeriğini artifact olarak döndür.

BAĞLAM:
$context

Çıktı yalnızca geçerli JSON olsun. Açıklama, Markdown çiti veya JSON dışı metin ekleme.
''';
  }

  String _buildContext({
    required ProjectSpec projectSpec,
    required List<String> relevantFiles,
    Map<String, String> fileExcerpts = const <String, String>{},
  }) {
    final files = List.unmodifiable(relevantFiles);
    final buffer = StringBuffer()
      ..writeln('PROJECT_SPEC')
      ..writeln('projectName: ${projectSpec.projectName}')
      ..writeln('description: ${projectSpec.description}')
      ..writeln('packageName: ${projectSpec.packageName}')
      ..writeln('architecture: ${projectSpec.architecture.name}')
      ..writeln('features: ${projectSpec.features.join(', ')}')
      ..writeln('requiredPackages: ${projectSpec.requiredPackages.join(', ')}')
      ..writeln('screens: ${projectSpec.screens.join(', ')}')
      ..writeln('acceptanceCriteria: ${projectSpec.acceptanceCriteria.join(' | ')}')
      ..writeln('includeTests: ${projectSpec.includeTests}')
      ..writeln('includeReadme: ${projectSpec.includeReadme}')
      ..writeln()
      ..writeln('RELEVANT_FILES');

    if (files.isEmpty) {
      buffer.writeln('(none)');
    } else {
      for (final file in files) {
        buffer.writeln('- $file');
      }
    }

    if (fileExcerpts.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('ONCEKI_AJANLARIN_CIKTISI (uyumlu kalmak icin bu dosyalara dayan)');
      fileExcerpts.forEach((path, excerpt) {
        buffer
          ..writeln('--- $path ---')
          ..writeln(excerpt);
      });
    }

    return buffer.toString();
  }
}
