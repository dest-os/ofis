import '../../domain/memory_intelligence/memory_consolidation_result.dart';
import '../../domain/memory_intelligence/memory_fact.dart';
import '../../domain/memory_intelligence/memory_reliability.dart';
import 'memory_intelligence_repository.dart';

class MemoryConsolidationService {
  final MemoryIntelligenceRepository repository;

  MemoryConsolidationService({required this.repository});

  Future<MemoryConsolidationResult> consolidate() async {
    final facts = await repository.all();
    final groups = <String, List<MemoryFact>>{};
    for (final fact in facts) {
      groups.putIfAbsent(fact.statement.trim().toLowerCase(), () => []).add(fact);
    }

    var superseded = 0;
    for (final group in groups.values) {
      if (group.length < 2) continue;
      group.sort((a, b) => _rank(b).compareTo(_rank(a)));
      for (final duplicate in group.skip(1)) {
        if (!duplicate.superseded) {
          await repository.save(MemoryFact(
            id: duplicate.id,
            statement: duplicate.statement,
            sourceType: duplicate.sourceType,
            reliability: duplicate.reliability,
            createdAt: duplicate.createdAt,
            validUntil: duplicate.validUntil,
            superseded: true,
          ));
          superseded++;
        }
      }
    }

    return MemoryConsolidationResult(
      examined: facts.length,
      retained: facts.length - superseded,
      superseded: superseded,
    );
  }

  int _rank(MemoryFact fact) {
    final source = fact.sourceType == MemorySourceType.archive ? 10 : 0;
    return source + fact.reliability.index;
  }
}
