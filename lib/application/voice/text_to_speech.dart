import '../../domain/voice/tts_request.dart';

abstract interface class TextToSpeechEngine {
  Future<void> speak(TtsRequest request);
  Future<void> stop();
}
