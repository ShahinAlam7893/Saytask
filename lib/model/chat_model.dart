enum MessageType { user, bot, event, task } 

class ChatMessage {
  final String message;
  final MessageType type;
  final DateTime? createdAt; 
  final String? responseType; 
  final DateTime? eventTime; 
  final String? eventTitle;
  final bool? callMe;
  final String? notification;
  final String? note;
  final String? messageId; 

  ChatMessage({
    required this.message,
    required this.type,
    this.createdAt,
    this.responseType,
    this.eventTime,
    this.eventTitle,
    this.callMe,
    this.notification,
    this.note,
    this.messageId,
  });

  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    final role = json['role'] as String;
    final content = json['content'] as String;
    final createdAt = DateTime.parse(json['created_at'] as String);
    final responseType = json['response_type'] as String?;
    final metadata = json['metadata'] as Map<String, dynamic>?;

    MessageType type;
    if (role == 'user') {
      type = MessageType.user;
    } else if (responseType == 'event') {
      type = MessageType.event;
    } else if (responseType == 'task') {
      type = MessageType.task;
    } else {
      type = MessageType.bot;
    }

    return ChatMessage(
      message: content,
      type: type,
      createdAt: createdAt,
      responseType: responseType,
      eventTime: metadata?['date'] != null ? DateTime.parse(metadata?['date']) : null,
      eventTitle: metadata?['title'] ?? content,
      callMe: metadata?['call_me'] as bool?,
      notification: metadata?['notification'] as String?,
      note: metadata?['note'] as String?,
    );
  }
}