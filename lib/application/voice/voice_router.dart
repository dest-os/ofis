import '../../domain/voice/voice_command.dart';
import '../../domain/voice/voice_decision.dart';
import 'voice_command_guard.dart';

class VoiceRouter {
  VoiceRouter({VoiceCommandGuard? guard}) : _guard = guard ?? VoiceCommandGuard();
  final VoiceCommandGuard _guard;

  VoiceDecision route(VoiceCommand command) => _guard.evaluate(command);
}
