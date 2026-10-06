import '../../domain/voice/voice_command.dart';

/// Türkçe sesli komutları teknik ayrıntı göstermeden uygulama eylemlerine çevirir.
class VoiceCommandParser {
  const VoiceCommandParser();

  VoiceCommandAction parse(String transcript) {
    final text = _normalize(transcript);
    if (text.isEmpty) return const VoiceCommandAction.none();

    if (_containsAny(text, const ['dur', 'dinlemeyi bitir', 'dinlemeyi durdur', 'dinlemeyi kapat'])) {
      return const VoiceCommandAction.stop();
    }
    if (_containsAny(text, const ['sohbet ac', 'sohbeti ac', 'sohbete git'])) {
      return const VoiceCommandAction.openChat();
    }
    if (_containsAny(text, const ['ayarlar ac', 'ayarlari ac', 'ayarlara git', 'sistem ayarlari ac'])) {
      return const VoiceCommandAction.openSettings();
    }
    if (_containsAny(text, const ['canli operasyon ac', 'canli operasyonu ac', 'canli operasyona git', 'canli operasyon'])) {
      return const VoiceCommandAction.openLiveOperations();
    }
    if (text.startsWith('mobil uygulama uret') || text.startsWith('mobil uygulamayi uret')) {
      final request = transcript
          .replaceFirst(RegExp(r'^\s*mobil\s+uygulama(?:yı|yi|yi)?\s+üret\s*[,;:\-]?\s*', caseSensitive: false), '')
          .trim();
      return VoiceCommandAction.mobileProduction(request.isEmpty ? null : request);
    }
    return VoiceCommandAction.unknown(transcript);
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _containsAny(String text, List<String> values) => values.any(text.contains);
}

class VoiceCommandAction {
  const VoiceCommandAction._({required this.type, this.request, this.originalText});

  const VoiceCommandAction.none() : this._(type: VoiceCommandActionType.none);
  const VoiceCommandAction.stop() : this._(type: VoiceCommandActionType.stop);
  const VoiceCommandAction.openChat() : this._(type: VoiceCommandActionType.openChat);
  const VoiceCommandAction.openSettings() : this._(type: VoiceCommandActionType.openSettings);
  const VoiceCommandAction.openLiveOperations() : this._(type: VoiceCommandActionType.openLiveOperations);
  const VoiceCommandAction.mobileProduction(String? request)
      : this._(type: VoiceCommandActionType.mobileProduction, request: request);
  const VoiceCommandAction.unknown(String text)
      : this._(type: VoiceCommandActionType.unknown, originalText: text);

  final VoiceCommandActionType type;
  final String? request;
  final String? originalText;

  VoiceCommand toDomainCommand() => VoiceCommand(text: originalText ?? request ?? '');
}

enum VoiceCommandActionType { none, stop, openChat, openSettings, openLiveOperations, mobileProduction, unknown }
