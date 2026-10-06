import 'package:flutter_test/flutter_test.dart';

import 'package:dest_os_ares/application/live_operations/live_operations_store.dart';
import 'package:dest_os_ares/domain/live_operations/live_operation_status.dart';

void main() {
  test('gerçek ilerleme ve CEO düzeltme olayı canlı duruma yansır', () async {
    final store = LiveOperationsStore();
    store.start(id: 'test', title: 'Mobil uygulama üretimi');

    store.progress(
      id: 'test',
      message: 'CEO: düzeltme denemesi 2/3.',
    );

    expect(store.activeOperation?.status, LiveOperationStatus.running);
    expect(store.activeOperation?.currentStep, 'CEO düzeltme');
    expect(store.activeOperation?.agentId, 'CEO');
    expect(store.events.first, 'CEO: düzeltme denemesi 2/3.');

    store.complete(id: 'test', message: 'Mobil uygulama üretimi tamamlandı.');
    expect(store.activeOperation, isNull);
    expect(store.operations.first.status, LiveOperationStatus.completed);

    await store.dispose();
  });

  test('başlangıçta sahte operasyon bulunmaz', () {
    final store = LiveOperationsStore();
    expect(store.operations, isEmpty);
    expect(store.events, isEmpty);
  });
}
