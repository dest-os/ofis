import '../../domain/agents/agent_capability.dart';
import '../../domain/ceo/ceo_intent.dart';

class CeoIntentParser {
  CeoIntent parse(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();

    if (text.isEmpty) {
      return const CeoIntent(
        type: CeoIntentType.unknown,
        rawText: '',
      );
    }

    if (_containsAny(lower, const ['durdur', 'iptal et', 'sonlandır'])) {
      return CeoIntent(
        type: CeoIntentType.stopWork,
        rawText: text,
        goal: text,
      );
    }

    if (_containsAny(lower, const ['devam et', 'kaldığın yerden'])) {
      return CeoIntent(
        type: CeoIntentType.continueWork,
        rawText: text,
        goal: text,
      );
    }

    if (_isCodeGenerationIntent(lower)) {
      return CeoIntent(
        type: CeoIntentType.codeGeneration,
        rawText: text,
        goal: text,
        priority: _priority(lower),
        requiredCapabilities: const <AgentCapability>[
          AgentCapability.codeGeneration,
        ],
      );
    }

    if (_containsAny(lower, const ['görev oluştur', 'görev oluştur', 'yapılacak'])) {
      return CeoIntent(
        type: CeoIntentType.createTask,
        rawText: text,
        goal: text,
        priority: _priority(lower),
      );
    }

    if (_containsAny(lower, const ['planla', 'proje planı', 'plan oluştur'])) {
      return CeoIntent(
        type: CeoIntentType.planProject,
        rawText: text,
        goal: text,
        priority: _priority(lower),
      );
    }

    if (_containsAny(lower, const ['incele', 'kontrol et', 'değerlendir'])) {
      return CeoIntent(
        type: CeoIntentType.reviewWork,
        rawText: text,
        goal: text,
      );
    }

    return CeoIntent(
      type: CeoIntentType.informationRequest,
      rawText: text,
      goal: text,
    );
  }

  bool _isCodeGenerationIntent(String text) {
    return _containsAny(text, const [
      'uygulama üret',
      'uygulama oluştur',
      'uygulama yap',
      'apk yap',
      'apk oluştur',
      'flutter projesi oluştur',
      'flutter projesi yap',
      'flutter uygulaması oluştur',
      'kod üret',
      'kod oluştur',
      'proje kodla',
      'yazılım oluştur',
    ]);
  }

  bool _containsAny(String text, List<String> values) {
    return values.any(text.contains);
  }

  String _priority(String text) {
    if (text.contains('acil') || text.contains('kritik')) {
      return 'critical';
    }
    if (text.contains('öncelikli') || text.contains('yüksek')) {
      return 'high';
    }
    if (text.contains('düşük')) {
      return 'low';
    }
    return 'normal';
  }
}
