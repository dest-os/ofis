import '../../domain/interaction/chat_message.dart';

class ChatService {
  final List<ChatMessage> _messages = <ChatMessage>[];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void add(ChatMessage message) => _messages.add(message);

  void clear() => _messages.clear();
}
