import '../../core/ids/ares_id.dart';

class AresTask {
  AresTask({
    required Object id,
    required this.title,
    required this.description,
    this.status = 'RECEIVED',
    this.priority = 'normal',
    DateTime? createdAt,
  })  : id = id is AresId ? id : AresId(id.toString()),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final AresId id;
  final String title;
  final String description;
  String status;
  final String priority;
  final DateTime createdAt;

  AresTask copyWith({
    Object? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? createdAt,
  }) {
    return AresTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  void changeStatus(String newStatus) {
    status = newStatus;
  }
}

typedef Task = AresTask;
