import 'ai_center_profile.dart';

class AiCenterSelection {
  const AiCenterSelection({required this.profile, required this.requiresApproval, required this.reason});
  final AiCenterProfile profile;
  final bool requiresApproval;
  final String reason;
}
