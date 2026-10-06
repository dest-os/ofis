import '../../domain/memory_intelligence/memory_fact.dart';

abstract interface class MemoryIntelligenceRepository {
  Future<void> save(MemoryFact fact);
  Future<List<MemoryFact>> all();
}
