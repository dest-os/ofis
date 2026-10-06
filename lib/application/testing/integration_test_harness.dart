import '../../domain/testing/integration_test_result.dart';

class IntegrationTestHarness {
  final List<IntegrationTestResult> _results = [];

  List<IntegrationTestResult> get results => List.unmodifiable(_results);

  IntegrationTestResult runCheck({
    required String testId,
    required bool Function() check,
    String successMessage = 'Kontrol başarılı.',
    String failureMessage = 'Kontrol başarısız.',
  }) {
    final passed = check();
    final result = IntegrationTestResult(
      testId: testId,
      status: passed
          ? IntegrationTestStatus.passed
          : IntegrationTestStatus.failed,
      message: passed ? successMessage : failureMessage,
      completedAt: DateTime.now(),
    );
    _results.add(result);
    return result;
  }

  bool get allPassed =>
      _results.isNotEmpty && _results.every((result) => result.passed);
}
