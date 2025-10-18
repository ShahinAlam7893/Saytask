enum MessageType { user, bot, event }

class ChatMessage {
  final String message;
  final MessageType type;
  final DateTime? eventTime; // for event card
  final String? eventTitle;
  final bool? callMe;

  ChatMessage({
    required this.message,
    required this.type,
    this.eventTime,
    this.eventTitle,
    this.callMe,
  });
}
