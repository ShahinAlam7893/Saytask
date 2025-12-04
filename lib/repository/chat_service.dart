import 'package:flutter/material.dart';
import 'package:saytask/model/chat_model.dart';
import 'package:saytask/repository/chat_repository.dart'; 

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ChatRepository _repository; 
  bool isLoading = false;

  List<ChatMessage> get messages => _messages;

  ChatViewModel() : _repository = ChatRepository();

  Future<void> fetchHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await _repository.getChatHistory();
      final List<dynamic> apiMessages = data['messages'];
      _messages.clear();
      for (var msg in apiMessages) {
        _messages.add(ChatMessage.fromApi(msg));
      }
    } catch (e) {
      print('Error fetching history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message) async {
    _messages.add(ChatMessage(
      message: message,
      type: MessageType.user,
      createdAt: DateTime.now(),
      responseType: 'response',
    ));
    notifyListeners();

    isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.sendMessage(message);

      final aiMessage = response['message'] as String;
      final responseType = response['response_type'] as String;
      final date = response['date'] as String?;
      final time = response['time'] as String?;
      final messageId = response['message_id'] as String?;

      DateTime? eventTime;
      if (date != null && time != null) {
        eventTime = DateTime.parse('$date $time'); 
      } else if (date != null) {
        eventTime = DateTime.parse(date);
      }

      MessageType type;
      if (responseType == 'event') {
        type = MessageType.event;
      } else if (responseType == 'task') {
        type = MessageType.task;
      } else {
        type = MessageType.bot;
      }

      _messages.add(ChatMessage(
        message: aiMessage,
        type: type,
        createdAt: DateTime.now(),
        responseType: responseType,
        eventTime: eventTime,
        eventTitle: aiMessage,
        messageId: messageId,
      ));
    } catch (e) {
   
      print('Error sending message: $e');
      _messages.add(ChatMessage(
        message: 'Error: Could not get response',
        type: MessageType.bot,
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  void deleteMessage(ChatMessage msg) {
    _messages.remove(msg);
    notifyListeners();
  }

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
  Future<Map<String, dynamic>> classifyMessage(String message) async {
    return await _repository.classifyMessage(message);
  }
}