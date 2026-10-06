enum TaskPriority { critical, high, normal, low }

extension TaskPriorityX on TaskPriority {
  String get value => name.toUpperCase();

  int get weight {
    switch (this) {
      case TaskPriority.critical:
        return 100;
      case TaskPriority.high:
        return 75;
      case TaskPriority.normal:
        return 50;
      case TaskPriority.low:
        return 25;
    }
  }
}
