// lib/model/event_model.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String locationAddress;
  DateTime? eventDateTime;
  final int reminderMinutes;
  final bool callMe;
  final bool isCompleted;

  Event({
    String? id,
    required this.title,
    this.description = '',
    this.locationAddress = '',
    this.eventDateTime,
    this.reminderMinutes = 0,
    this.callMe = false,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  DateTime? get localDateTime => eventDateTime;
  TimeOfDay? get time => eventDateTime != null ? TimeOfDay.fromDateTime(eventDateTime!) : null;
  DateTime? get date => eventDateTime;

  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> reminders = [];
    if (reminderMinutes > 0) {
      reminders.add({
        "time_before": reminderMinutes,
        "types": callMe ? ["notification", "call"] : ["notification"],
      });
    }

    final utcDateTime = eventDateTime?.toUtc();

    return {
      "title": title,
      "description": description,
      "location_address": locationAddress.isEmpty ? null : locationAddress,
      "event_datetime": utcDateTime?.toIso8601String(),
      "reminders": reminders,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime? parsedUtc;

    final eventDateTimeStr = json['event_datetime'] as String?;
    final startTimeStr = json['start_time'] as String?;

    if (eventDateTimeStr != null && eventDateTimeStr != 'null') {
      parsedUtc = DateTime.tryParse(eventDateTimeStr);
    } else if (startTimeStr != null && startTimeStr != 'null') {
      parsedUtc = DateTime.tryParse(startTimeStr);
    }

    final DateTime? localDateTime = parsedUtc?.toLocal();

    int reminderMinutes = 0;
    bool callMe = false;

    final reminders = json['reminders'] as List<dynamic>? ?? [];
    if (reminders.isNotEmpty) {
      final first = reminders.first as Map<String, dynamic>;
      reminderMinutes = (first['time_before'] as num?)?.toInt() ?? 0;
      final types = (first['types'] as List<dynamic>?)?.cast<String>() ?? [];
      callMe = types.contains('call');
    }

    return Event(
      id: json['id'] as String,
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      locationAddress: json['location_address'] ?? '',
      eventDateTime: localDateTime,
      reminderMinutes: reminderMinutes,
      callMe: callMe,
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? locationAddress,
    DateTime? eventDateTime,
    int? reminderMinutes,
    bool? callMe,
    bool? isCompleted,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      callMe: callMe ?? this.callMe,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}