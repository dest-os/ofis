import '../../core/ids/ares_id.dart';

enum ChatMessageRole { user, assistant, system }

class ChatMessage {
  ChatMessage({
    String? id,
    required this.conversationId,
    required this.role,
    required this.text,
    DateTime? createdAt,
  })  : id = id ?? AresId.generate().value,
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String conversationId;
  final ChatMessageRole role;
  final String text;
  final DateTime createdAt;
}
