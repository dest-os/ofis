import 'dart:async';

import '../../domain/live_operations/live_operation.dart';
import '../../domain/live_operations/live_operation_status.dart';

/// Üretim sırasında oluşan gerçek olayları tek bir canlı akışta tutar.
/// Uygulama belleğinde yaşar; gizli bilgi saklamaz.
class LiveOperationsStore {
  static const int maxEvents = 12;
  static const int maxOperations = 8;

  final Map<String, LiveOperation> _operations = <String, LiveOperation>{};
  final List<String> _events = <String>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  List<LiveOperation> get operations {
    final items = _operations.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(items);
  }

  List<String> get events => List.unmodifiable(_events);

  LiveOperation? get activeOperation {
    final items = _operations.values
        .where((item) => item.status.isActive)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items.isEmpty ? null : items.first;
  }

  void start({required String id, required String title}) {
    _operations[id] = LiveOperation(
      id: id,
      title: title,
      status: LiveOperationStatus.running,
      progress: 0,
      updatedAt: DateTime.now(),
      currentStep: 'Başlatılıyor',
      message: 'Üretim başlatıldı.',
      priority: 100,
    );
    _addEvent('$title başladı.');
    _notify();
  }

  void progress({required String id, required String message}) {
    final current = _operations[id];
    if (current == null) return;

    final isCeoRetry = message.contains('CEO: düzeltme denemesi');
    final nextProgress = _progressFromMessage(message, current.progress);
    _operations[id] = current.copyWith(
      status: LiveOperationStatus.running,
      progress: nextProgress,
      updatedAt: DateTime.now(),
      currentStep: isCeoRetry ? 'CEO düzeltme' : _stepFromMessage(message),
      agentId: _agentFromMessage(message),
      message: _cleanMessage(message),
    );
    _addEvent(_cleanMessage(message));
    _notify();
  }

  void complete({required String id, required String message}) {
    final current = _operations[id];
    if (current == null) return;
    _operations[id] = current.copyWith(
      status: LiveOperationStatus.completed,
      progress: 1,
      updatedAt: DateTime.now(),
      currentStep: 'Tamamlandı',
      message: message,
    );
    _addEvent(message);
    _trimOperations();
    _notify();
  }

  void fail({required String id, required String message}) {
    final current = _operations[id];
    if (current == null) return;
    _operations[id] = current.copyWith(
      status: LiveOperationStatus.failed,
      updatedAt: DateTime.now(),
      currentStep: 'Hata',
      message: message,
    );
    _addEvent(message);
    _trimOperations();
    _notify();
  }

  Future<void> dispose() => _changes.close();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void _addEvent(String message) {
    final text = message.trim();
    if (text.isEmpty) return;
    _events.insert(0, text);
    if (_events.length > maxEvents) {
      _events.removeRange(maxEvents, _events.length);
    }
  }

  void _trimOperations() {
    if (_operations.length <= maxOperations) return;
    final sorted = _operations.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final keep = sorted.take(maxOperations).map((item) => item.id).toSet();
    _operations.removeWhere((key, _) => !keep.contains(key));
  }

  static double _progressFromMessage(String message, double current) {
    if (message.startsWith('İstek:')) return current < .05 ? .05 : current;
    if (message.startsWith('Plan:')) return current < .10 ? .10 : current;
    if (message.startsWith('Scaffold:')) return current < .18 ? .18 : current;
    if (message.contains('Product Manager')) return current < .25 ? .25 : current;
    if (message.contains('System Architect')) return current < .35 ? .35 : current;
    if (message.startsWith('Domain:')) return current < .45 ? .45 : current;
    if (message.startsWith('Application:')) return current < .55 ? .55 : current;
    if (message.startsWith('Presentation:')) return current < .65 ? .65 : current;
    if (message.contains('CEO:')) return current < .72 ? .72 : current;
    if (message.startsWith('QA:')) return current < .82 ? .82 : current;
    if (message.startsWith('Yazma:')) return current < .92 ? .92 : current;
    if (message.startsWith('Doğrulama:')) return current < .97 ? .97 : current;
    return current;
  }

  static String _stepFromMessage(String message) {
    final separator = message.indexOf(':');
    if (separator > 0) return message.substring(0, separator).trim();
    return 'Üretim';
  }

  static String _agentFromMessage(String message) {
    const known = <String>[
      'Product Manager',
      'System Architect',
      'Domain',
      'Application',
      'Presentation',
      'QA',
      'DevOps',
      'CEO',
      'Scaffold',
    ];
    for (final name in known) {
      if (message.startsWith('$name:') || message.contains('$name:')) return name;
    }
    return 'ARES';
  }

  static String _cleanMessage(String message) =>
      message.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
}
