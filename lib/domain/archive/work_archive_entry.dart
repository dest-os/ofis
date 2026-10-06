import '../../core/ids/ares_id.dart';

/// Tamamlanmış işlerin tekrar kullanılabilmesi için kalıcı arşiv kaydı.
/// Silme işlemi için soft-delete alanı korunur.
class WorkArchiveEntry {
  const WorkArchiveEntry({
    required this.id,
    required this.title,
    required this.summary,
    required this.completedAt,
    this.taskId,
    this.projectId,
    this.memoryNamespace,
    this.tags = const [],
    this.reusable = true,
    this.isDeleted = false,
    this.deletedAt,
  });

  final AresId id;
  final String title;
  final String summary;
  final DateTime completedAt;
  final String? taskId;
  final String? projectId;
  final String? memoryNamespace;
  final List<String> tags;
  final bool reusable;
  final bool isDeleted;
  final DateTime? deletedAt;

  WorkArchiveEntry copyWith({
    String? title,
    String? summary,
    DateTime? completedAt,
    String? taskId,
    String? projectId,
    String? memoryNamespace,
    List<String>? tags,
    bool? reusable,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return WorkArchiveEntry(
      id: id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      completedAt: completedAt ?? this.completedAt,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      memoryNamespace: memoryNamespace ?? this.memoryNamespace,
      tags: List.unmodifiable(tags ?? this.tags),
      reusable: reusable ?? this.reusable,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
