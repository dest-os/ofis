import '../../domain/interaction/interaction_target.dart';

class MasterUiInteractionService {
  InteractionTarget? resolve(double x, double y, List<({InteractionTarget target, double left, double top, double width, double height})> hitboxes) {
    for (final hitbox in hitboxes) {
      final insideX = x >= hitbox.left && x <= hitbox.left + hitbox.width;
      final insideY = y >= hitbox.top && y <= hitbox.top + hitbox.height;
      if (insideX && insideY) return hitbox.target;
    }
    return null;
  }
}
