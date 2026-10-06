import '../../domain/voice/voice_command.dart';
import '../../domain/voice/voice_decision.dart';
import '../../domain/voice/voice_risk.dart';

class VoiceCommandGuard {
  VoiceDecision evaluate(VoiceCommand command, {VoiceRisk risk = VoiceRisk.low}) {
    if (command.text.trim().isEmpty) {
      return const VoiceDecision(allowed: false, requiresApproval: false, reason: 'Boş ses komutu.');
    }
    if (risk == VoiceRisk.high || risk == VoiceRisk.critical || command.requiresApproval) {
      return const VoiceDecision(allowed: true, requiresApproval: true, reason: 'Kritik ses komutu için İbrahim onayı gerekir.');
    }
    return const VoiceDecision(allowed: true, requiresApproval: false);
  }
}
