import '../../core/ids/ares_id.dart';

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  alternativeRequested,
}

class ApprovalRequest {
  ApprovalRequest({
    required this.id,
    required this.reason,
    required this.requestedAt,
  });

  final AresId id;
  final String reason;
  final DateTime requestedAt;
  ApprovalStatus status = ApprovalStatus.pending;
}
