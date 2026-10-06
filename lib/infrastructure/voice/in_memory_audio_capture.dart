import '../../application/voice/audio_capture.dart';
import '../../domain/voice/audio_chunk.dart';

class InMemoryAudioCapture implements AudioCapture {
  bool _running = false;

  @override
  Future<void> start() async => _running = true;

  @override
  Stream<AudioChunk> chunks() => _running ? const Stream<AudioChunk>.empty() : const Stream<AudioChunk>.empty();

  @override
  Future<void> stop() async => _running = false;
}
