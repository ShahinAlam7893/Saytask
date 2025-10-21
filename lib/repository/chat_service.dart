import 'package:flutter/material.dart';
import 'package:saytask/model/chat_model.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  /// Send a message and trigger auto-reply
  void sendMessage(String message) {
    // Add user message
    _messages.add(ChatMessage(message: message, type: MessageType.user));
    notifyListeners();

    // Auto reply after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (message.toLowerCase().contains("dog food")) {
        // Bot message
        _messages.add(ChatMessage(
          message: "I'll make sure you have a reminder set for buying dog food tomorrow afternoon!",
          type: MessageType.bot,
        ));

        // Add event card for tomorrow 3 PM
        final now = DateTime.now();
        final tomorrow3PM = DateTime(now.year, now.month, now.day + 1, 15, 0);
        _messages.add(ChatMessage(
          message: "",
          type: MessageType.event,
          eventTitle: "Buy dog food",
          eventTime: tomorrow3PM,
          callMe: true,
          notification: "At time of event",
          note: "Remember to buy dog food tomorrow",
        ));
      } else {
        _messages.add(ChatMessage(
          message: "Thank you for your message.",
          type: MessageType.bot,
        ));
      }
      notifyListeners();
    });
  }

  /// Delete a message
  void deleteMessage(ChatMessage msg) {
    _messages.remove(msg);
    notifyListeners();
  }

  /// Edit an event message (title, time, notification, note)
  void editEventMessage(
      ChatMessage msg, {
        String? newTitle,
        DateTime? newTime,
        String? newNotification,
        String? newNote,
      }) {
    final index = _messages.indexOf(msg);
    if (index != -1) {
      final old = _messages[index];
      _messages[index] = ChatMessage(
        message: old.message,
        type: old.type,
        eventTitle: newTitle ?? old.eventTitle,
        eventTime: newTime ?? old.eventTime,
        callMe: old.callMe,
        notification: newNotification ?? old.notification,
        note: newNote ?? old.note,
      );
      notifyListeners();
    }
  }
}
