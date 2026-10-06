enum ApprovalRequirement {
  none,
  userApprovalRequired,
  securityApprovalRequired,
}

class ApprovalRequirementResult {
  const ApprovalRequirementResult({
    required this.requirement,
    required this.reason,
  });

  final ApprovalRequirement requirement;
  final String reason;

  bool get isApprovedAutomatically {
    return requirement == ApprovalRequirement.none;
  }
}
