import '../../domain/ui_interaction/interaction_target.dart';

class MasterUiHitboxService {
  const MasterUiHitboxService();

  InteractionHitbox listenerHitbox() => const InteractionHitbox(
        target: InteractionTarget.chat,
        left: 0.05,
        top: 0.35,
        width: 0.20,
        height: 0.35,
      );

  InteractionHitbox eyeHitbox() => const InteractionHitbox(
        target: InteractionTarget.aiCenter,
        left: 0.38,
        top: 0.25,
        width: 0.24,
        height: 0.30,
      );
}
