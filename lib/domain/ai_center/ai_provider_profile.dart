import 'ai_center_category.dart';

class AiProviderProfile {
  const AiProviderProfile({
    required this.provider,
    required this.model,
    required this.address,
    required this.category,
    required this.capabilities,
    required this.verified,
  });

  final String provider;
  final String model;
  final String address;
  final AiCenterCategory category;
  final List<String> capabilities;
  final bool verified;
}
