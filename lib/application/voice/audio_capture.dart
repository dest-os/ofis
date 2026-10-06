import '../../domain/voice/audio_chunk.dart';

abstract interface class AudioCapture {
  Future<void> start();
  Stream<AudioChunk> chunks();
  Future<void> stop();
}
