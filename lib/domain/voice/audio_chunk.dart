class AudioChunk {
  const AudioChunk(this.bytes, {required this.sampleRate});

  final List<int> bytes;
  final int sampleRate;
}
