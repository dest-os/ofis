class ChatAttachment {
  const ChatAttachment({required this.name, required this.mimeType, required this.sizeBytes, this.path});
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String? path;
}
