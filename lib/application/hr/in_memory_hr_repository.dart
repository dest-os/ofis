import '../../core/result/ares_result.dart';
import '../../domain/hr/employee_hr_record.dart';
import '../../domain/hr/employee_lifecycle_event.dart';
import '../../domain/hr/performance_review.dart';
import '../../domain/hr/training_record.dart';
import 'hr_repository.dart';

class InMemoryHrRepository implements HrRepository {
  final Map<String, EmployeeHrRecord> _records = {};
  final Map<String, TrainingRecord> _training = {};
  final Map<String, PerformanceReview> _reviews = {};
  final List<EmployeeLifecycleEvent> _lifecycle = [];

  @override
  AresResult<void> saveRecord(EmployeeHrRecord record) {
    _records[record.employeeId] = record;
    return const AresSuccess<void>(null);
  }

  @override
  AresResult<EmployeeHrRecord?> findRecord(String employeeId) =>
      AresSuccess<EmployeeHrRecord?>(_records[employeeId]);

  @override
  List<EmployeeHrRecord> getAllRecords() => List.unmodifiable(_records.values);

  @override
  AresResult<void> saveTraining(TrainingRecord record) {
    _training[record.id] = record;
    return const AresSuccess<void>(null);
  }

  @override
  AresResult<void> saveReview(PerformanceReview review) {
    _reviews[review.id] = review;
    return const AresSuccess<void>(null);
  }

  @override
  AresResult<void> saveLifecycleEvent(EmployeeLifecycleEvent event) {
    _lifecycle.add(event);
    return const AresSuccess<void>(null);
  }

  @override
  List<EmployeeLifecycleEvent> lifecycleEventsFor(String employeeId) =>
      List.unmodifiable(_lifecycle.where((event) => event.employeeId == employeeId));
}
