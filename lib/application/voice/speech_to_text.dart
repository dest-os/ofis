import '../../domain/voice/audio_chunk.dart';
import '../../domain/voice/stt_result.dart';

abstract interface class SpeechToTextEngine {
  Future<void> start({String languageCode = 'tr-TR'});
  Future<SttResult> process(AudioChunk audio);
  Future<void> stop();
}
