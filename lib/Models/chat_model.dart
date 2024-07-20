class ChatMessage {
  final String message;
  final bool isUserMessage;

  ChatMessage({required this.message, required this.isUserMessage});

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      message: data['message'] ?? '',
      isUserMessage: data['isUser'] ?? false,
    );
  }
}
