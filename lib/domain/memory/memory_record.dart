import 'memory_scope.dart';
import 'memory_type.dart';

class MemoryRecord {
  const MemoryRecord({
    required this.id,
    required this.content,
    required this.type,
    required this.scope,
    required this.createdAt,
    this.projectId,
    this.taskId,
    this.confidence = 1.0,
    this.source,
    this.tags = const <String>[],
    this.archived = false,
  });

  final String id;
  final String content;
  final MemoryType type;
  final MemoryScope scope;
  final DateTime createdAt;
  final String? projectId;
  final String? taskId;
  final double confidence;
  final String? source;
  final List<String> tags;
  final bool archived;

  MemoryRecord copyWith({
    String? id,
    String? content,
    MemoryType? type,
    MemoryScope? scope,
    DateTime? createdAt,
    String? projectId,
    String? taskId,
    double? confidence,
    String? source,
    List<String>? tags,
    bool? archived,
  }) {
    return MemoryRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      archived: archived ?? this.archived,
    );
  }
}
