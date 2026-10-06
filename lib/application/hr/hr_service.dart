import '../../core/ids/ares_id.dart';
import '../../core/result/ares_result.dart';
import '../../domain/employees/employee.dart';
import '../../domain/employees/employee_status.dart';
import '../../domain/hr/employee_hr_record.dart';
import '../../domain/hr/employee_lifecycle_event.dart';
import '../../domain/hr/performance_review.dart';
import '../../domain/hr/training_record.dart';
import '../../domain/employees/employee_performance.dart';
import 'hr_repository.dart';

class HrService {
  final HrRepository repository;

  const HrService({required this.repository});

  EmployeeHrRecord initialize(Employee employee) {
    final now = DateTime.now().toUtc();
    final record = EmployeeHrRecord(
      employeeId: employee.id.value,
      status: employee.status,
      training: const [],
      reviews: const [],
      performance: _emptyPerformance(employee.id.value),
    );
    repository.saveRecord(record);
    repository.saveLifecycleEvent(EmployeeLifecycleEvent(
      id: AresId('${employee.id.value}-hr-${now.microsecondsSinceEpoch}'),
      employeeId: employee.id.value,
      from: employee.status,
      to: employee.status,
      reason: 'İK kaydı oluşturuldu.',
      createdAt: now,
    ));
    return record;
  }

  TrainingRecord createTraining({
    required String employeeId,
    required String skillId,
    required String title,
  }) {
    final record = TrainingRecord(
      id: AresId('${employeeId}-training-${DateTime.now().toUtc().microsecondsSinceEpoch}').value,
      employeeId: employeeId,
      skillId: skillId,
      title: title,
      completion: 0,
      passed: false,
      startedAt: DateTime.now().toUtc(),
    );
    repository.saveTraining(record);
    return record;
  }

  bool updateTraining({
    required String employeeId,
    required String trainingId,
    required double completion,
    required bool passed,
  }) {
    final existing = _trainingFor(employeeId, trainingId);
    if (existing == null) return false;
    repository.saveTraining(existing.update(
      completion: completion,
      passed: passed,
      completedAt: completion >= 1 ? DateTime.now().toUtc() : null,
    ));
    return true;
  }

  PerformanceReview addReview({
    required String employeeId,
    required double qualityScore,
    required double reliabilityScore,
    required double speedScore,
    required String summary,
    bool recommendedForPromotion = false,
    bool recommendedForSuspension = false,
  }) {
    final review = PerformanceReview(
      id: AresId('${employeeId}-review-${DateTime.now().toUtc().microsecondsSinceEpoch}').value,
      employeeId: employeeId,
      reviewedAt: DateTime.now().toUtc(),
      qualityScore: qualityScore,
      reliabilityScore: reliabilityScore,
      speedScore: speedScore,
      summary: summary,
      recommendedForPromotion: recommendedForPromotion,
      recommendedForSuspension: recommendedForSuspension,
    );
    repository.saveReview(review);
    return review;
  }

  bool canPromote(EmployeeHrRecord record) {
    return record.trainingComplete && record.latestReviewScore >= 0.75;
  }

  bool canRetire(Employee employee) => !employee.permanent;

  bool canSuspend(Employee employee) => !employee.permanent;

  bool canEnterProbation(Employee employee) =>
      employee.status == EmployeeStatus.created || employee.status == EmployeeStatus.training;

  bool canActivate(EmployeeHrRecord record) =>
      record.trainingComplete && record.latestReviewScore >= 0.60;

  TrainingRecord? _trainingFor(String employeeId, String trainingId) {
    final records = repository.findRecord(employeeId);
    if (records is! AresSuccess<EmployeeHrRecord?>) return null;
    final hr = records.value;
    if (hr == null) return null;
    for (final item in hr.training) {
      if (item.id == trainingId) return item;
    }
    return null;
  }

  EmployeePerformance _emptyPerformance(String employeeId) {
    return EmployeePerformance(employeeId: employeeId);
  }
}
