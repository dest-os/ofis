import '../../core/ids/ares_id.dart';
import '../../domain/voice/voice_session.dart';
import '../../domain/voice/voice_state.dart';

class VoiceSessionService {
  VoiceSessionService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  VoiceSession start() => VoiceSession(id: AresId.newId(), state: VoiceState.listening, startedAt: _now());

  VoiceSession process(VoiceSession session, String transcript) =>
      session.copyWith(state: VoiceState.processing, transcript: transcript);

  VoiceSession speak(VoiceSession session) => session.copyWith(state: VoiceState.speaking);
  VoiceSession interrupt(VoiceSession session) => session.copyWith(state: VoiceState.interrupted);
  VoiceSession finish(VoiceSession session) => session.copyWith(state: VoiceState.idle);
}
