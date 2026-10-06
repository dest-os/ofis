import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../domain/voice/stt_result.dart';

/// Android tablet üzerindeki gerçek konuşma tanıma servisi.
class VoiceCommandService {
  VoiceCommandService({stt.SpeechToText? engine}) : _engine = engine ?? stt.SpeechToText();

  final stt.SpeechToText _engine;

  bool get isListening => _engine.isListening;

  Future<VoiceStartResult> start({
    required void Function(SttResult result) onResult,
    void Function(String status)? onStatus,
    void Function(String message)? onError,
  }) async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      await openAppSettings();
      return VoiceStartResult.denied;
    }

    final available = await _engine.initialize(
      onStatus: onStatus,
      onError: (_) => onError?.call('Ses tanıma kullanılamadı.'),
      debugLogging: false,
    );
    if (!available) return VoiceStartResult.unsupported;

    await _engine.listen(
      localeId: 'tr-TR',
      onResult: (result) {
        onResult(SttResult(
          text: result.recognizedWords,
          confidence: result.confidence,
          isFinal: result.finalResult,
        ));
      },
    );
    return VoiceStartResult.started;
  }

  Future<void> stop() => _engine.stop();

  Future<void> cancel() => _engine.cancel();
}

enum VoiceStartResult { started, denied, unsupported }
