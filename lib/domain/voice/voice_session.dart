import 'voice_state.dart';

class VoiceSession {
  const VoiceSession({
    required this.id,
    required this.state,
    required this.startedAt,
    this.transcript = '',
    this.errorMessage,
  });

  final String id;
  final VoiceState state;
  final DateTime startedAt;
  final String transcript;
  final String? errorMessage;

  VoiceSession copyWith({
    VoiceState? state,
    String? transcript,
    String? errorMessage,
  }) => VoiceSession(
        id: id,
        state: state ?? this.state,
        startedAt: startedAt,
        transcript: transcript ?? this.transcript,
        errorMessage: errorMessage,
      );
}
