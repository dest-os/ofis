import 'release_gate_status.dart';

class ReleaseGate {
  final String id;
  final String title;
  final bool required;
  final ReleaseGateStatus status;
  final String message;

  const ReleaseGate({
    required this.id,
    required this.title,
    required this.required,
    required this.status,
    this.message = '',
  });

  bool get passed => status == ReleaseGateStatus.passed;
}
