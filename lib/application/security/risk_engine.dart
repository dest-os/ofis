import '../../domain/security/risk_assessment.dart';
import '../../domain/security/risk_level.dart';

class RiskEngine {
  RiskAssessment assess({
    required RiskLevel baseLevel,
    required String reason,
    bool externalWrite = false,
    bool touchesSensitiveData = false,
  }) {
    var level = baseLevel;
    if (externalWrite && level.index < RiskLevel.high.index) level = RiskLevel.high;
    if (touchesSensitiveData && level.index < RiskLevel.high.index) level = RiskLevel.high;
    return RiskAssessment(
      level: level,
      reason: reason,
      externalWrite: externalWrite,
      touchesSensitiveData: touchesSensitiveData,
    );
  }
}
