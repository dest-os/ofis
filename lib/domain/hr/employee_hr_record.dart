import '../employees/employee_performance.dart';
import '../employees/employee_status.dart';
import 'performance_review.dart';
import 'training_record.dart';

class EmployeeHrRecord {
  final String employeeId;
  final EmployeeStatus status;
  final List<TrainingRecord> training;
  final List<PerformanceReview> reviews;
  final EmployeePerformance performance;
  final DateTime? probationStartedAt;
  final DateTime? probationEndsAt;
  final DateTime? lastReviewAt;

  const EmployeeHrRecord({
    required this.employeeId,
    required this.status,
    required this.training,
    required this.reviews,
    required this.performance,
    this.probationStartedAt,
    this.probationEndsAt,
    this.lastReviewAt,
  });

  bool get trainingComplete =>
      training.isNotEmpty && training.every((item) => item.passed && item.completion >= 1);

  double get latestReviewScore => reviews.isEmpty ? 0 : reviews.last.overallScore;
}
