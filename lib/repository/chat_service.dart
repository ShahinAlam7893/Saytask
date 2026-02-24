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
  bool isTyping = false;

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
      debugPrint("History loaded: ${_messages.length} messages");
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message) async {
    _messages.add(
      ChatMessage(
        message: message,
        type: MessageType.user,
        createdAt: DateTime.now(),
        responseType: 'response',

        // eventTime: null,
      ),
    );
    notifyListeners();

    isTyping = true;
    notifyListeners();

    try {
      final response = await _repository.sendMessage(message);

      isTyping = false;
      notifyListeners();

      final aiMessage = response['message'] as String? ?? '';
      final responseType = response['response_type'] as String? ?? 'response';
      final messageId = response['message_id'] as String?;

      String? eventTitle = response['title'] as String?;
      String? note = response['description'] as String?;
      DateTime? eventTime;
      bool callMe = false;
      String notification = "30 minutes before";

      // Parse event time (UTC → local)
      final eventDatetimeStr =
          response['event_datetime'] as String? ??
          response['start_time'] as String?;
      if (eventDatetimeStr != null) {
        try {
          eventTime = DateTime.parse(eventDatetimeStr).toUtc().toLocal();
        } catch (e) {
          debugPrint('Error parsing event_datetime/start_time: $e');
        }
      }

      // Parse reminders
      final reminders = response['reminders'] as List<dynamic>?;
      if (reminders != null && reminders.isNotEmpty) {
        final firstReminder = reminders.first as Map<String, dynamic>?;
        if (firstReminder != null) {
          final timeBefore = firstReminder['time_before'] as int?;
          final types =
              (firstReminder['types'] as List<dynamic>?)?.cast<String>() ?? [];

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
      }

      eventTitle ??= aiMessage;
      note ??= aiMessage;

      final MessageType type = switch (responseType) {
        'event' => MessageType.event,
        'task' => MessageType.task,
        _ => MessageType.bot,
      };

      final chatMessage = ChatMessage(
        message: aiMessage,
        type: type,
        createdAt: DateTime.now(),
        responseType: responseType,
        eventTime: eventTime ?? DateTime.now().add(const Duration(hours: 1)),
        eventTitle: eventTitle,
        callMe: callMe,
        notification: notification,
        note: note,
        messageId: messageId,
        itemId: response['item_id']?.toString(),
      );

      _messages.add(chatMessage);
      notifyListeners();

      if (responseType == 'event' || responseType == 'task') {
        await _saveToBackend(chatMessage, response);
        // Reload history to ensure itemId & latest state are in _messages
        await fetchHistory();
      } else if (responseType == 'note') {
        await _saveNoteToBackend(aiMessage);
      }
    } catch (e) {
      isTyping = false;
      notifyListeners();
      debugPrint('Error sending message: $e');
    }
  }

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

      final startTimeStr = eventTime.toUtc().toIso8601String();

      final remindersRaw = apiResponse['reminders'] as List<dynamic>? ?? [];

      final remindersList = remindersRaw.isNotEmpty
          ? remindersRaw
                .map(
                  (r) => {
                    "time_before": r['time_before'] ?? 30,
                    "types":
                        (r['types'] as List<dynamic>?)?.cast<String>() ??
                        ["notification"],
                  },
                )
                .toList()
          : [
              {
                "time_before": 30,
                "types": ["notification"],
              },
            ];

      if (msg.responseType == 'task') {
        await _voiceActionRepo.createTask({
          "title": title,
          "description": description,
          "start_time": startTimeStr,
          "duration": 60,
          "tags": apiResponse['tags'] ?? [],
          "reminders": remindersList,
          "completed": false,
        });
        debugPrint('Task created/saved: $title');
      } else if (msg.responseType == 'event') {
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
          "location_address": apiResponse['location_address'] ?? "",
        });
        debugPrint('Event created/saved: $title');
      }
    } catch (e, stack) {
      debugPrint('Failed to save new item to backend: $e');
      debugPrint('Stack: $stack');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _saveNoteToBackend(String noteText) async {
    if (isSaving) return;

    isSaving = true;
    notifyListeners();

    try {
      await _voiceActionRepo.createNote(noteText);
      debugPrint('Note saved to backend');
    } catch (e) {
      debugPrint('Failed to save note: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveEditedMessage(ChatMessage msg) async {
    if (msg.type == MessageType.user || msg.type == MessageType.bot) return;

    final itemId = msg.itemId ?? msg.messageId;
    if (itemId == null) {
      debugPrint(
        'Cannot save edit - no valid itemId for message: ${msg.message}',
      );
      debugPrint(
        'Message details: type=${msg.type}, \n eventTitle=${msg.eventTitle}, \n eventTime=${msg.eventTime}, \n notification=${msg.notification}, \n note=${msg.note}',
      );
      return;
    }

    isSaving = true;
    notifyListeners();

    try {
      final eventTime =
          msg.eventTime ?? DateTime.now().add(const Duration(hours: 1));

      final title = msg.eventTitle ?? msg.message;
      final description = msg.note ?? msg.message;
      final startTimeUtc = eventTime.toUtc().toIso8601String();
      final endTimeUtc = eventTime
          .add(const Duration(hours: 1))
          .toUtc()
          .toIso8601String();

      final timeBefore = switch (msg.notification) {
        "5 minutes before" => 5,
        "10 minutes before" => 10,
        "15 minutes before" => 15,
        "30 minutes before" => 30,
        "1 hour before" => 60,
        "2 hours before" => 120,
        "At time of event" => 0,
        _ => 30,
      };

      final reminders = [
        {
          "time_before": timeBefore,
          "types": ["notification", if (msg.callMe) "call"],
        },
      ];

      debugPrint(
        "saveEditedMessage called → itemId: '${itemId ?? 'NULL'}' | type: ${msg.type} | title: '$title'",
      );

      final baseData = {
        "title": title,
        "description": description,
        "reminders": reminders,
      };

      if (itemId != null && itemId.isNotEmpty) {
        debugPrint("→ UPDATE path (itemId: $itemId)");

        if (msg.type == MessageType.task) {
          final updateData = {
            ...baseData,
            "start_time": startTimeUtc,
            "duration": 60,
            "completed": false,
          };
          await _voiceActionRepo.updateTask(itemId, updateData);
          debugPrint("Task UPDATED successfully: $title (id: $itemId)");
        } else if (msg.type == MessageType.event) {
          final updateData = {
            ...baseData,
            "event_datetime": startTimeUtc,
            "start_time": startTimeUtc,
            "end_time": endTimeUtc,
            "location_address": "",
          };
          await _voiceActionRepo.updateEvent(itemId, updateData);
          debugPrint("Event UPDATED successfully: $title (id: $itemId)");
        }
      } else {
        debugPrint(
          "→ CREATE path (no valid itemId) - this should be rare for edits!",
        );

        if (msg.type == MessageType.task) {
          final createData = {
            ...baseData,
            "start_time": startTimeUtc,
            "duration": 60,
            "tags": [],
            "completed": false,
          };
          await _voiceActionRepo.createTask(createData);
          debugPrint("New task CREATED: $title");
        } else if (msg.type == MessageType.event) {
          final createData = {
            ...baseData,
            "event_datetime": startTimeUtc,
            "start_time": startTimeUtc,
            "end_time": endTimeUtc,
            "location_address": "",
          };
          await _voiceActionRepo.createEvent(createData);
          debugPrint("New event CREATED: $title");
        }
      }
      debugPrint("Reloading history after save...");
      await fetchHistory();
    } catch (e, stackTrace) {
      debugPrint('Failed to save edited message: $e');
      debugPrint('Stack trace: $stackTrace');

      // Better error message for duplicates
      String errorMsg = 'Failed to save changes';
      if (e.toString().toLowerCase().contains('duplicate') ||
          e.toString().contains('already exists')) {
        errorMsg =
            'Cannot save - duplicate item (same title & time already exists)';
      }
      debugPrint("USER ERROR: $errorMsg");
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
    String? itemId,
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
        itemId: itemId,
      );
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> classifyMessage(String message) async {
    return await _repository.classifyMessage(message);
  }
}
