enum EventPriority {
  low,
  normal,
  high,
  critical,
}

extension EventPriorityX on EventPriority {
  String get value => name.toUpperCase();
}
