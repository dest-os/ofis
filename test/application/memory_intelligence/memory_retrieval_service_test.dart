import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/memory_intelligence/in_memory_memory_intelligence_repository.dart';
import 'package:dest_os_ares/application/memory_intelligence/memory_retrieval_service.dart';
import 'package:dest_os_ares/domain/memory_intelligence/memory_fact.dart';
import 'package:dest_os_ares/domain/memory_intelligence/memory_query.dart';
import 'package:dest_os_ares/domain/memory_intelligence/memory_reliability.dart';
import 'package:dest_os_ares/domain/memory_intelligence/memory_source_type.dart';

void main() {
  test('memory retrieval returns relevant facts first', () async {
    final repository = InMemoryMemoryIntelligenceRepository();
    await repository.save(MemoryFact(
      id: '1',
      statement: 'ARES projesi Flutter ile geliştiriliyor',
      sourceType: MemorySourceType.archive,
      reliability: MemoryReliability.verified,
      createdAt: DateTime(2026),
    ));
    await repository.save(MemoryFact(
      id: '2',
      statement: 'Bugün hava güneşli',
      sourceType: MemorySourceType.external,
      reliability: MemoryReliability.low,
      createdAt: DateTime(2026),
    ));

    final service = MemoryRetrievalService(repository: repository);
    final result = await service.search(const MemoryQuery(text: 'ARES Flutter'));

    expect(result, isNotEmpty);
    expect(result.first.fact.id, '1');
  });
}
