import '../../application/voice/speech_to_text.dart';
import '../../domain/voice/audio_chunk.dart';
import '../../domain/voice/stt_result.dart';

class InMemorySpeechToText implements SpeechToTextEngine {
  bool _running = false;

  @override
  Future<void> start({String languageCode = 'tr-TR'}) async => _running = true;

  @override
  Future<SttResult> process(AudioChunk audio) async =>
      SttResult(text: _running ? '' : '', confidence: 0, isFinal: true);

  @override
  Future<void> stop() async => _running = false;
}
