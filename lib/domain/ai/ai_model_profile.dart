import 'ai_capability.dart';
import 'ai_category.dart';
import 'ai_verification_status.dart';

class AiModelProfile {
  final String id;
  final String provider;
  final String name;
  final String address;
  final AiCategory category;
  final AiVerificationStatus verificationStatus;
  final Set<AiCapability> capabilities;
  final String license;
  final String pricingSummary;
  final String limitsSummary;
  final bool requiresApproval;
  final DateTime updatedAt;

  const AiModelProfile({
    required this.id,
    required this.provider,
    required this.name,
    required this.address,
    required this.category,
    required this.verificationStatus,
    required this.capabilities,
    required this.license,
    required this.pricingSummary,
    required this.limitsSummary,
    required this.requiresApproval,
    required this.updatedAt,
  });
}
