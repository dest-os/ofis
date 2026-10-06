import 'ai_center_category.dart';

class AiCenterProfile {
  const AiCenterProfile({
    required this.provider,
    required this.model,
    required this.endpoint,
    required this.category,
    required this.capabilities,
    this.license,
    this.pricing,
    this.limits,
    this.verified = false,
  });

  final String provider;
  final String model;
  final String endpoint;
  final AiCenterCategory category;
  final List<String> capabilities;
  final String? license;
  final String? pricing;
  final String? limits;
  final bool verified;

  bool get requiresApproval => category == AiCenterCategory.paid || category == AiCenterCategory.unknown;
}
