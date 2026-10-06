import '../../core/security/cost_policy.dart';

class AiRuntimeRequest {
  const AiRuntimeRequest({
    required this.instruction,
    required this.costClass,
    this.provider,
    this.model,
    this.metadata = const <String, Object?>{},
  });

  final String instruction;
  final AiCostClass costClass;
  final String? provider;
  final String? model;
  final Map<String, Object?> metadata;
}
