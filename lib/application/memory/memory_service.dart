import '../../domain/memory/memory_record.dart';
import '../../domain/memory/memory_scope.dart';
import '../../domain/memory/memory_type.dart';
import 'memory_repository.dart';

class MemoryService {
  MemoryService(this._repository);

  final MemoryRepository _repository;

  Future<MemoryRecord> remember({
    required String id,
    required String content,
    required MemoryType type,
    required MemoryScope scope,
    String? projectId,
    String? taskId,
    double confidence = 1.0,
    String? source,
    List<String> tags = const <String>[],
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Hafıza içeriği boş olamaz.');
    }

    final memory = MemoryRecord(
      id: id,
      content: content.trim(),
      type: type,
      scope: scope,
      createdAt: DateTime.now().toUtc(),
      projectId: projectId,
      taskId: taskId,
      confidence: confidence,
      source: source,
      tags: List<String>.unmodifiable(tags),
    );

    await _repository.save(memory);
    return memory;
  }

  Future<List<MemoryRecord>> retrieve(String query) {
    return _repository.search(query);
  }

  Future<void> forget(String id) {
    return _repository.remove(id);
  }

  Future<void> archive(String id) {
    return _repository.archive(id);
  }
}
