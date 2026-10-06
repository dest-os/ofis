import '../../domain/memory/memory_record.dart';

abstract interface class MemoryRepository {
  Future<void> save(MemoryRecord memory);
  Future<MemoryRecord?> getById(String id);
  Future<List<MemoryRecord>> getAll();
  Future<List<MemoryRecord>> search(String query);
  Future<void> archive(String id);
  Future<void> remove(String id);
}
