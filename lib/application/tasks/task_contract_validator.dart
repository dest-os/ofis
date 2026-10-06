import '../../domain/tasks/task_contract.dart';
import '../../domain/tasks/task_contract_result.dart';

class TaskContractValidator {
  TaskContractResult validate({
    required TaskContract contract,
    required List<String> completedCriteria,
  }) {
    final completed = completedCriteria.toSet();

    final missing = contract.acceptanceCriteria
        .where((criterion) => !completed.contains(criterion))
        .toList(growable: false);

    if (missing.isEmpty) {
      return TaskContractResult(
        status: TaskContractResultStatus.accepted,
        completedCriteria: List.unmodifiable(completedCriteria),
        missingCriteria: const <String>[],
      );
    }

    return TaskContractResult(
      status: TaskContractResultStatus.needsRevision,
      completedCriteria: List.unmodifiable(completedCriteria),
      missingCriteria: List.unmodifiable(missing),
      notes: 'Kabul kriterlerinin tamamı karşılanmadı.',
    );
  }
}
