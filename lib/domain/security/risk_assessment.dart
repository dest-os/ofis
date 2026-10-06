import 'risk_level.dart';

class RiskAssessment {
  final RiskLevel level;
  final String reason;
  final bool externalWrite;
  final bool touchesSensitiveData;

  const RiskAssessment({
    required this.level,
    required this.reason,
    this.externalWrite = false,
    this.touchesSensitiveData = false,
  });
}
