enum ChatMessageRole { user, ares, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime createdAt;
}
