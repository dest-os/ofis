import '../../core/ids/ares_id.dart';
import 'chat_message.dart';

class ChatConversation {
  ChatConversation({String? id, required this.title, List<ChatMessage>? messages, DateTime? updatedAt})
      : id = id ?? AresId.generate(),
        messages = messages ?? <ChatMessage>[],
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  final List<ChatMessage> messages;
  DateTime updatedAt;
}
