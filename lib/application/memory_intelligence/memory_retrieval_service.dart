import '../../domain/memory_intelligence/memory_fact.dart';
import '../../domain/memory_intelligence/memory_match.dart';
import '../../domain/memory_intelligence/memory_query.dart';
import '../../domain/memory_intelligence/memory_retrieval_policy.dart';
import 'memory_intelligence_repository.dart';

class MemoryRetrievalService {
  final MemoryIntelligenceRepository repository;
  final MemoryRetrievalPolicy policy;

  MemoryRetrievalService({required this.repository, this.policy = const MemoryRetrievalPolicy()});

  Future<List<MemoryMatch>> search(MemoryQuery query) async {
    final now = query.at ?? DateTime.now();
    final tokens = _tokens(query.text);
    final facts = await repository.all();
    final matches = <MemoryMatch>[];

    for (final fact in facts) {
      if (!fact.isValidAt(now)) continue;
      final score = _score(fact, tokens);
      if (score > 0) matches.add(MemoryMatch(fact: fact, score: score));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    final limit = query.limit.clamp(1, policy.maxResults);
    return matches.take(limit).toList();
  }

  double _score(MemoryFact fact, Set<String> tokens) {
    if (tokens.isEmpty) return 0;
    final words = _tokens(fact.statement);
    final overlap = tokens.where(words.contains).length;
    var score = overlap / tokens.length;
    if (fact.sourceType.name == 'archive' && policy.archiveFirst) score += 0.15;
    score += fact.reliability.index * 0.03;
    return score;
  }

  Set<String> _tokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ]+'))
      .where((item) => item.length > 1)
      .toSet();
}
