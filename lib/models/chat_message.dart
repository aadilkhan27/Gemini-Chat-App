// lib/models/chat_message.dart

enum MessageRole { user, assistant }

enum MessageStatus { sending, streaming, done, error }

class ChatMessage {
  final String id;
  final MessageRole role;
  String text;
  MessageStatus status;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.status = MessageStatus.done,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get hasError => status == MessageStatus.error;

  ChatMessage copyWith({String? text, MessageStatus? status}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }
}
