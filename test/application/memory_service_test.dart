import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/memory/in_memory_memory_repository.dart';
import 'package:dest_os_ares/application/memory/memory_service.dart';
import 'package:dest_os_ares/domain/memory/memory_scope.dart';
import 'package:dest_os_ares/domain/memory/memory_type.dart';

void main() {
  test('hafızaya bilgi yazılır ve aranabilir', () async {
    final service = MemoryService(InMemoryMemoryRepository());

    await service.remember(
      id: 'memory-1',
      content: 'ARES kişisel hafızası',
      type: MemoryType.preference,
      scope: MemoryScope.personal,
    );

    final result = await service.retrieve('kişisel');

    expect(result, hasLength(1));
    expect(result.single.id, 'memory-1');
  });

  test('boş hafıza kaydı kabul edilmez', () {
    final service = MemoryService(InMemoryMemoryRepository());

    expect(
      () => service.remember(
        id: 'memory-2',
        content: '   ',
        type: MemoryType.fact,
        scope: MemoryScope.personal,
      ),
      throwsArgumentError,
    );
  });
}
