// lib/model/event_model.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String locationAddress;
  final DateTime? eventDateTime; 
  final int reminderMinutes;
  final bool callMe;

  Event({
    String? id,
    required this.title,
    this.description = '',
    this.locationAddress = '',
    DateTime? eventDateTime,
    this.reminderMinutes = 0,
    this.callMe = false,
  })  : id = id ?? const Uuid().v4(),
        eventDateTime = eventDateTime;

  // ────────────────────── GETTERS (Local Time) ──────────────────────
  DateTime? get localDateTime => eventDateTime;
  TimeOfDay? get time => eventDateTime != null ? TimeOfDay.fromDateTime(eventDateTime!) : null;
  DateTime? get date => eventDateTime;

  // ────────────────────── TO JSON (Send UTC to server) ──────────────────────
  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> reminders = [];
    if (reminderMinutes > 0) {
      reminders.add({
        "time_before": reminderMinutes,
        "types": callMe ? ["notification", "call"] : ["notification"],
      });
    }

    return {
      "title": title,
      "description": description,
      "location_address": locationAddress.isEmpty ? null : locationAddress,
      "event_datetime": eventDateTime?.toUtc().toIso8601String(), // ← UTC!
      "reminders": reminders,
    };
  }

  // ────────────────────── FROM JSON (Convert UTC → Local) ──────────────────────
  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime? parsedUtc;

if (json['event_datetime'] != null && json['event_datetime'] != 'null') {
    parsedUtc = DateTime.tryParse(json['event_datetime']);
  }

  else if (json['start_time'] != null && json['start_time'] != 'null') {
    parsedUtc = DateTime.tryParse(json['start_time']);
  }
  else if (json['date'] != null) {
    final dateStr = json['date'] as String;
    final timeStr = json['time'] as String?;
    if (timeStr != null) {
      parsedUtc = DateTime.tryParse("$dateStr $timeStr");
    } else {
      parsedUtc = DateTime.tryParse(dateStr);
    }
  }

    final DateTime? localDateTime = parsedUtc?.toLocal();

    int reminderMinutes = 0;
    bool callMe = false;
    final reminders = json['reminders'] as List<dynamic>? ?? [];
    if (reminders.isNotEmpty) {
      final first = reminders.first as Map<String, dynamic>;
      reminderMinutes = first['time_before'] ?? 0;
      final types = (first['types'] as List<dynamic>?) ?? [];
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
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      callMe: callMe ?? this.callMe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}