import '../../domain/update/update_plan.dart';
class UpdateGuard {
  bool canInstall(UpdatePlan plan) => plan.signatureValid && plan.artifactHash.trim().isNotEmpty;
}
