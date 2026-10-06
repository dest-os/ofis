import '../../domain/migration/migration_plan.dart';
class MigrationService {
  bool canApply(MigrationPlan plan, {required bool approvalGranted}) {
    if (plan.fromVersion >= plan.toVersion) return false;
    if (plan.destructive && !approvalGranted) return false;
    return plan.steps.isNotEmpty;
  }
}
