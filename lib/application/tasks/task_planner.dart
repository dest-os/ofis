import '../../domain/tasks/task.dart';

class TaskPlan {
  const TaskPlan({
    required this.task,
    required this.steps,
  });

  final AresTask task;
  final List<String> steps;
}

abstract interface class TaskPlanner {
  TaskPlan createPlan(AresTask task);
}

class BasicTaskPlanner implements TaskPlanner {
  const BasicTaskPlanner();

  @override
  TaskPlan createPlan(AresTask task) {
    return TaskPlan(
      task: task,
      steps: const [
        'Görevi anla',
        'Planı oluştur',
        'Uygula',
        'Doğrula',
        'Sonucu kaydet',
      ],
    );
  }
}
