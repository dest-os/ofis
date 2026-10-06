import '../../domain/memory_intelligence/memory_fact.dart';
import 'memory_intelligence_repository.dart';

class InMemoryMemoryIntelligenceRepository
    implements MemoryIntelligenceRepository {
  final List<MemoryFact> _facts = <MemoryFact>[];

  @override
  Future<void> save(MemoryFact fact) async {
    _facts.removeWhere((item) => item.id == fact.id);
    _facts.add(fact);
  }

  @override
  Future<List<MemoryFact>> all() async => List.unmodifiable(_facts);
}
