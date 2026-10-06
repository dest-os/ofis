import '../../core/result/ares_result.dart';
import '../../domain/hr/employee_hr_record.dart';
import '../../domain/hr/employee_lifecycle_event.dart';
import '../../domain/hr/performance_review.dart';
import '../../domain/hr/training_record.dart';

abstract interface class HrRepository {
  AresResult<void> saveRecord(EmployeeHrRecord record);
  AresResult<EmployeeHrRecord?> findRecord(String employeeId);
  List<EmployeeHrRecord> getAllRecords();
  AresResult<void> saveTraining(TrainingRecord record);
  AresResult<void> saveReview(PerformanceReview review);
  AresResult<void> saveLifecycleEvent(EmployeeLifecycleEvent event);
  List<EmployeeLifecycleEvent> lifecycleEventsFor(String employeeId);
}
