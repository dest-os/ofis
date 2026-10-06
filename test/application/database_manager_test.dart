import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/database/database_manager.dart';
import 'package:dest_os_ares/domain/database/entity_record.dart';

void main() {
  test('veritabanı kaydı transaction ile saklanır', () async {
    final manager = DatabaseManager();
    await manager.initialize();

    final transaction = await manager.database.beginTransaction();

    await transaction.insert(
      EntityRecord(
        id: 'record-1',
        entityType: 'test',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        data: const <String, Object?>{'value': 'ARES'},
      ),
    );

    await transaction.commit();

    final record = await manager.database.find('test', 'record-1');

    expect(record?.data['value'], 'ARES');
  });

  test('rollback işlemi kaydı geri alır', () async {
    final manager = DatabaseManager();
    await manager.initialize();

    final transaction = await manager.database.beginTransaction();

    await transaction.insert(
      EntityRecord(
        id: 'record-2',
        entityType: 'test',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        data: const <String, Object?>{'value': 'rollback'},
      ),
    );

    await transaction.rollback();

    final record = await manager.database.find('test', 'record-2');

    expect(record, isNull);
  });
}
