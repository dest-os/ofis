import '../../core/ids/ares_id.dart';
import '../employees/employee_status.dart';

class EmployeeLifecycleEvent {
  final AresId id;
  final String employeeId;
  final EmployeeStatus from;
  final EmployeeStatus to;
  final String reason;
  final DateTime createdAt;

  const EmployeeLifecycleEvent({
    required this.id,
    required this.employeeId,
    required this.from,
    required this.to,
    required this.reason,
    required this.createdAt,
  });
}
