import '../../domain/memory_intelligence/memory_fact.dart';
import '../../domain/memory_intelligence/memory_match.dart';
import '../../domain/memory_intelligence/memory_query.dart';
import 'memory_consolidation_service.dart';
import 'memory_intelligence_repository.dart';
import 'memory_retrieval_service.dart';

class MemoryIntelligenceService {
  final MemoryIntelligenceRepository repository;
  late final MemoryRetrievalService retrieval;
  late final MemoryConsolidationService consolidation;

  MemoryIntelligenceService({required this.repository}) {
    retrieval = MemoryRetrievalService(repository: repository);
    consolidation = MemoryConsolidationService(repository: repository);
  }

  Future<void> remember(MemoryFact fact) => repository.save(fact);

  Future<List<MemoryMatch>> recall(MemoryQuery query) => retrieval.search(query);

  Future<int> consolidate() async => (await consolidation.consolidate()).superseded;
}
