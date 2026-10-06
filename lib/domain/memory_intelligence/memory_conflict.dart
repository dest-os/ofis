import 'memory_fact.dart';

class MemoryConflict {
  final MemoryFact first;
  final MemoryFact second;
  final String reason;

  const MemoryConflict({
    required this.first,
    required this.second,
    required this.reason,
  });
}
