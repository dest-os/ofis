import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/voice/voice_session_service.dart';
import 'package:dest_os_ares/domain/voice/voice_state.dart';

void main() {
  test('ses oturumu doğru durumlarla ilerler', () {
    final service = VoiceSessionService(now: () => DateTime(2026, 1, 1));
    final session = service.start();
    expect(session.state, VoiceState.listening);
    final processing = service.process(session, 'merhaba');
    expect(processing.state, VoiceState.processing);
    expect(processing.transcript, 'merhaba');
    expect(service.speak(processing).state, VoiceState.speaking);
  });
}
