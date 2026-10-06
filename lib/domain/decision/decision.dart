import 'decision_type.dart';

class Decision {
  const Decision({
    required this.id,
    required this.type,
    required this.reason,
    required this.createdAt,
    this.requiresUserApproval = false,
    this.confidence = 1.0,
    this.alternatives = const <String>[],
  });

  final String id;
  final DecisionType type;
  final String reason;
  final DateTime createdAt;
  final bool requiresUserApproval;
  final double confidence;
  final List<String> alternatives;
}
