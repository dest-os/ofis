import '../../domain/memory_intelligence/memory_conflict.dart';
import '../../domain/memory_intelligence/memory_fact.dart';
import 'memory_intelligence_repository.dart';

class MemoryConflictService {
  final MemoryIntelligenceRepository repository;

  MemoryConflictService({required this.repository});

  Future<List<MemoryConflict>> findConflicts() async {
    final facts = await repository.all();
    final result = <MemoryConflict>[];
    for (var i = 0; i < facts.length; i++) {
      for (var j = i + 1; j < facts.length; j++) {
        final a = facts[i];
        final b = facts[j];
        if (a.superseded || b.superseded) continue;
        if (_sameTopic(a.statement, b.statement) && a.statement != b.statement) {
          result.add(MemoryConflict(
            first: a,
            second: b,
            reason: 'Aynı konu için farklı ifadeler bulundu.',
          ));
        }
      }
    }
    return result;
  }

  bool _sameTopic(String a, String b) {
    final aa = a.toLowerCase().split(RegExp(r'\s+')).take(3).join(' ');
    final bb = b.toLowerCase().split(RegExp(r'\s+')).take(3).join(' ');
    return aa.isNotEmpty && aa == bb;
  }
}
