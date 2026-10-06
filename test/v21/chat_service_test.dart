import 'package:flutter_test/flutter_test.dart';
import 'package:dest_os_ares/application/chat/chat_service.dart';
import 'package:dest_os_ares/domain/chat/chat_message.dart';

void main() {
  test('chat service user message ekler', () {
    final service = ChatService();
    final conversation = service.createConversation('Test');
    service.addUserMessage(conversation, 'Merhaba');
    expect(conversation.messages.single.role, ChatMessageRole.user);
    expect(conversation.messages.single.text, 'Merhaba');
  });
}
