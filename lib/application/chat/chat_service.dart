import '../../domain/chat/chat_attachment.dart';
import '../../domain/chat/chat_conversation.dart';
import '../../domain/chat/chat_message.dart';

class ChatService {
  ChatConversation createConversation(String title) => ChatConversation(title: title);

  ChatMessage addUserMessage(ChatConversation conversation, String text, {List<ChatAttachment> attachments = const []}) {
    final message = ChatMessage(conversationId: conversation.id, role: ChatMessageRole.user, text: text);
    conversation.messages.add(message);
    conversation.updatedAt = DateTime.now();
    return message;
  }

  ChatMessage addAssistantMessage(ChatConversation conversation, String text) {
    final message = ChatMessage(conversationId: conversation.id, role: ChatMessageRole.assistant, text: text);
    conversation.messages.add(message);
    conversation.updatedAt = DateTime.now();
    return message;
  }
}
