import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/database/database_manager.dart';
import 'package:dest_os_ares/application/memory/persistent_memory_repository.dart';
import 'package:dest_os_ares/domain/memory/memory_record.dart';
import 'package:dest_os_ares/domain/memory/memory_scope.dart';
import 'package:dest_os_ares/domain/memory/memory_type.dart';

void main() {
  test('hafıza kalıcı repository katmanında saklanabilir', () async {
    final database = DatabaseManager();
    await database.initialize();

    final repository = PersistentMemoryRepository(database);

    await repository.save(
      MemoryRecord(
        id: 'memory-15',
        content: 'V15 kalıcı hafıza testi',
        type: MemoryType.fact,
        scope: MemoryScope.personal,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final result = await repository.getById('memory-15');

    expect(result?.content, 'V15 kalıcı hafıza testi');
  });
}
