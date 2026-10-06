import '../../core/security/approval_requirement.dart';
import '../../domain/approvals/approval.dart';

abstract interface class ApprovalGate {
  Future<ApprovalRequest> requestApproval(
    ApprovalRequirementResult requirement,
  );
}
