import '../../application/voice/text_to_speech.dart';
import '../../domain/voice/tts_request.dart';

class InMemoryTextToSpeech implements TextToSpeechEngine {
  String? lastText;

  @override
  Future<void> speak(TtsRequest request) async => lastText = request.text;

  @override
  Future<void> stop() async => lastText = null;
}
