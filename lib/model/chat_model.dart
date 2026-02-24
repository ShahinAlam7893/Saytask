import 'package:flutter/material.dart';

enum MessageType { user, bot, event, task }

class ChatMessage {
  final String message;
  final MessageType type;
  final DateTime? createdAt;
  final String? responseType;
  final DateTime? eventTime;     
  final DateTime? endTime;
  final String? eventTitle;
  final bool callMe;
  final String notification;
  final String? note;
  final String? messageId;
  final String? itemId;

  ChatMessage({
    required this.message,
    required this.type,
    this.createdAt,
    this.responseType,
    this.eventTime,        
    this.endTime,
    this.eventTitle,
    this.callMe = false,
    this.notification = "At time of event",
    this.note,
    this.messageId,
    this.itemId,
  });

  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    final content = json['content'] as String? ?? '';

    // ────────────────────────────── Created At ──────────────────────────────
    DateTime? createdAt;
    final createdAtStr = json['created_at'] as String?;
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        createdAt = DateTime.parse(createdAtStr).toUtc().toLocal();
      } catch (_) {
        // silent fail
      }
    }

    // ────────────────────────────── Type ──────────────────────────────
    final responseType = json['response_type'] as String?;
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

    // ────────────────────────────── Times ──────────────────────────────
    DateTime? parsedEventTime;
    DateTime? parsedEndTime;

    final timeCandidates = [
      json['event_datetime'],
      json['start_time'],
      (json['metadata'] as Map?)?['event_datetime'],
      (json['metadata'] as Map?)?['start_time'],
    ];

    for (final raw in timeCandidates) {
      if (raw is String && raw.isNotEmpty) {
        try {
          parsedEventTime = DateTime.parse(raw).toUtc().toLocal();
          break;
        } catch (_) {}
      }
    }

    final endTimeCandidates = [
      json['end_time'],
      (json['metadata'] as Map?)?['end_time'],
    ];

    for (final raw in endTimeCandidates) {
      if (raw is String && raw.isNotEmpty) {
        try {
          parsedEndTime = DateTime.parse(raw).toUtc().toLocal();
          break;
        } catch (_) {}
      }
    }

    // Fallback: always have a valid eventTime
    final eventTime = parsedEventTime ?? DateTime.now().add(const Duration(hours: 1));

    // ────────────────────────────── Reminders ──────────────────────────────
    bool callMe = false;
    String notification = "At time of event";

    final remindersRaw = json['reminders'] ?? (json['metadata'] as Map?)?['reminders'];

    if (remindersRaw is List && remindersRaw.isNotEmpty) {
      final firstReminderMap = remindersRaw.firstWhere(
        (r) => r is Map<String, dynamic>,
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;

      if (firstReminderMap.isNotEmpty) {
        final reminder = Reminders.fromJson(firstReminderMap);
        callMe = reminder.types?.contains('call') ?? false;
        notification = _timeBeforeToLabel(reminder.timeBefore);
      }
    }

    // ────────────────────────────── Title, Note, itemId ──────────────────────────────
    final metadata = json['metadata'] as Map<String, dynamic>?;

    final title = json['title'] as String? ??
        metadata?['title'] as String? ??
        (type == MessageType.user ? null : content);

    final noteValue = json['description'] as String? ??
        metadata?['description'] as String? ??
        (type == MessageType.task || type == MessageType.event ? content : null);

    final itemId = json['item_id'] as String? ?? metadata?['item_id'] as String?;

    // Optional debug (remove later if not needed)
    debugPrint("Parsed ChatMessage: title=$title | itemId=$itemId | callMe=$callMe | time=$eventTime");

    return ChatMessage(
      message: content,
      type: type,
      createdAt: createdAt,
      responseType: responseType,
      eventTime: eventTime,
      endTime: parsedEndTime,
      eventTitle: title,
      callMe: callMe,
      notification: notification,
      note: noteValue,
      messageId: json['message_id']?.toString(),
      itemId: itemId,
    );
  }

  static String _timeBeforeToLabel(int? minutes) {
    if (minutes == null || minutes <= 0) return "At time of event";

    return switch (minutes) {
      5 => "5 minutes before",
      10 => "10 minutes before",
      15 => "15 minutes before",
      30 => "30 minutes before",
      60 => "1 hour before",
      120 => "2 hours before",
      _ => "$minutes minutes before",
    };
  }
}

class Reminders {
  final int? timeBefore;
  final List<String>? types;

  Reminders({
    this.timeBefore,
    this.types,
  });

  factory Reminders.fromJson(Map<String, dynamic> json) {
    return Reminders(
      timeBefore: json['time_before'] as int?,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .whereType<String>()
          .toList(),
    );
  }
}