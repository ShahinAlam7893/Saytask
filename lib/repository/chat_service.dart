// lib/view_model/chat_view_model.dart

import 'package:flutter/material.dart';
import 'package:saytask/model/chat_model.dart';
import 'package:saytask/repository/chat_repository.dart';
import 'package:saytask/repository/voice_action_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ChatRepository _repository;
  final VoiceActionRepository _voiceActionRepo = VoiceActionRepository();

  bool isLoading = false;
  bool isSaving = false;

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
      debugPrint('Error fetching history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

    Future<void> sendMessage(String message) async {
    // Add user message
    _messages.add(
      ChatMessage(
        message: message,
        type: MessageType.user,
        createdAt: DateTime.now(),
        responseType: 'response',
      ),
    );
    notifyListeners();

    isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.sendMessage(message);

      final aiMessage = response['message'] as String;
      final responseType = response['response_type'] as String;
      final messageId = response['message_id'] as String?;

      // Extract data directly from root level (new API format)
      String? eventTitle = response['title'] as String?;
      String? note = response['description'] as String?;
      DateTime? eventTime;
      bool? callMe = false;
      String notification = "30 minutes before"; // default

      // Parse event_datetime (UTC) → convert to local time
      final eventDatetimeStr = response['event_datetime'] as String?;
      if (eventDatetimeStr != null) {
        try {
          eventTime = DateTime.parse(eventDatetimeStr).toLocal();
        } catch (e) {
          debugPrint('Error parsing event_datetime: $e');
        }
      }

      // Handle reminders to set notification text and callMe
      final reminders = response['reminders'] as List<dynamic>?;
      if (reminders != null && reminders.isNotEmpty) {
        final firstReminder = reminders.first as Map<String, dynamic>;
        final timeBefore = firstReminder['time_before'] as int?;
        final types = (firstReminder['types'] as List<dynamic>?)?.cast<String>() ?? [];

        callMe = types.contains('call');

        notification = switch (timeBefore) {
          5 => "5 minutes before",
          10 => "10 minutes before",
          15 => "15 minutes before",
          30 => "30 minutes before",
          60 => "1 hour before",
          120 => "2 hours before",
          _ => "At time of event",
        };
      }

      // Fallbacks
      eventTitle ??= aiMessage;
      note ??= aiMessage;

      // Determine message type
      final MessageType type = switch (responseType) {
        'event' => MessageType.event,
        'task' => MessageType.task,
        _ => MessageType.bot,
      };

      // Create the chat message
      final chatMessage = ChatMessage(
        message: aiMessage,
        type: type,
        createdAt: DateTime.now(),
        responseType: responseType,
        eventTime: eventTime,
        eventTitle: eventTitle,
        callMe: callMe,
        notification: notification,
        note: note,
        messageId: messageId,
      );

      _messages.add(chatMessage);
      notifyListeners();

      if (responseType == 'event' || responseType == 'task') {
        await _saveToBackend(chatMessage, response);
      } else if (responseType == 'note') {
        await _saveNoteToBackend(aiMessage);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      _messages.add(
        ChatMessage(
          message: 'Error: Could not get response',
          type: MessageType.bot,
          createdAt: DateTime.now(),
        ),
      );
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // CRITICAL: Save event/task to backend
  Future<void> _saveToBackend(
    ChatMessage msg,
    Map<String, dynamic> apiResponse,
  ) async {
    if (isSaving) return;

    isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final eventTime = msg.eventTime ?? now.add(const Duration(hours: 1));
      final title = msg.eventTitle ?? msg.message;
      final description = msg.note ?? msg.message;

      // Build proper UTC time
      final startTimeStr = eventTime.toUtc().toIso8601String();

      if (msg.responseType == 'task') {
        // Extract reminders from API response
        final metadata = apiResponse['metadata'] as Map<String, dynamic>?;
        final reminders = metadata?['reminders'] as List<dynamic>? ?? [];

        final remindersList = reminders.isNotEmpty
            ? reminders
                  .map(
                    (r) => {
                      "time_before": r['time_before'] ?? 30,
                      "types": r['types'] ?? ["notification"],
                    },
                  )
                  .toList()
            : [
                {
                  "time_before": 30,
                  "types": ["notification"],
                },
              ];

        await _voiceActionRepo.createTask({
          "title": title,
          "description": description,
          "start_time": startTimeStr,
          "duration": 60,
          "tags": metadata?['tags'] ?? [],
          "reminders": remindersList,
          "completed": false,
        });

        debugPrint('✅ Task saved to backend: $title');
      } else if (msg.responseType == 'event') {
        final endTimeStr = eventTime
            .add(const Duration(hours: 1))
            .toUtc()
            .toIso8601String();
        final metadata = apiResponse['metadata'] as Map<String, dynamic>?;

        await _voiceActionRepo.createEvent({
          "title": title,
          "description": description,
          "event_datetime": startTimeStr,
          "start_time": startTimeStr,
          "end_time": endTimeStr,
          "location_address": metadata?['location'] ?? "",
        });

        debugPrint('✅ Event saved to backend: $title');
      }
    } catch (e) {
      debugPrint('❌ Failed to save to backend: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // Save note to backend
  Future<void> _saveNoteToBackend(String noteText) async {
    if (isSaving) return;

    isSaving = true;
    notifyListeners();

    try {
      await _voiceActionRepo.createNote(noteText);
      debugPrint('✅ Note saved to backend');
    } catch (e) {
      debugPrint('❌ Failed to save note: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // Manual save for edited messages
  Future<void> saveEditedMessage(ChatMessage msg) async {
    if (msg.type == MessageType.user || msg.type == MessageType.bot) return;

    isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final eventTime = msg.eventTime ?? now.add(const Duration(hours: 1));
      final title = msg.eventTitle ?? msg.message;
      final description = msg.note ?? msg.message;

      final startTimeStr = eventTime.toUtc().toIso8601String();

      if (msg.type == MessageType.task) {
        final reminders = msg.callMe == true
            ? [
                {
                  "time_before": 10,
                  "types": ["notification", "call"],
                },
                {
                  "time_before": 30,
                  "types": ["notification"],
                },
              ]
            : [
                {
                  "time_before": 30,
                  "types": ["notification"],
                },
              ];

        await _voiceActionRepo.createTask({
          "title": title,
          "description": description,
          "start_time": startTimeStr,
          "duration": 60,
          "tags": [],
          "reminders": reminders,
          "completed": false,
        });

        debugPrint('✅ Edited task saved: $title');
      } else if (msg.type == MessageType.event) {
        final endTimeStr = eventTime
            .add(const Duration(hours: 1))
            .toUtc()
            .toIso8601String();

        await _voiceActionRepo.createEvent({
          "title": title,
          "description": description,
          "event_datetime": startTimeStr,
          "start_time": startTimeStr,
          "end_time": endTimeStr,
          "location_address": "",
        });

        debugPrint('✅ Edited event saved: $title');
      }
    } catch (e) {
      debugPrint('❌ Failed to save edited message: $e');
      rethrow;
    } finally {
      isSaving = false;
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
        createdAt: old.createdAt,
        responseType: old.responseType,
        eventTitle: newTitle ?? old.eventTitle,
        eventTime: newTime ?? old.eventTime,
        callMe: old.callMe,
        notification: newNotification ?? old.notification,
        note: newNote ?? old.note,
        messageId: old.messageId,
      );
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> classifyMessage(String message) async {
    return await _repository.classifyMessage(message);
  }
}
