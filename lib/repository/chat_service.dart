import 'package:flutter/material.dart';
import 'package:saytask/model/chat_model.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  void sendMessage(String message) {
    // Add user message
    _messages.add(ChatMessage(message: message, type: MessageType.user));
    notifyListeners();

    // Auto reply
    Future.delayed(const Duration(seconds: 1), () {
      if (message.toLowerCase().contains("dog food")) {
        _messages.add(ChatMessage(
          message: "I'll make sure you have a reminder set for buying dog food tomorrow afternoon!",
          type: MessageType.bot,
        ));
        // Add event card for tomorrow 3 PM (15:00)
        final tomorrow3PM = DateTime.now()
            .add(const Duration(days: 1))
            .subtract(Duration(hours: DateTime.now().hour - 15, minutes: DateTime.now().minute))
            .add(Duration(minutes: 60 - DateTime.now().minute)); // Adjust to 15:00
        _messages.add(ChatMessage(
          message: "",
          type: MessageType.event,
          eventTitle: "Buy dog food",
          eventTime: tomorrow3PM,
          callMe: true,
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
}