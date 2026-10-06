import 'interaction_target.dart';

class InteractionHitbox {
  const InteractionHitbox({
    required this.target,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final InteractionTarget target;
  final double left;
  final double top;
  final double width;
  final double height;
}
