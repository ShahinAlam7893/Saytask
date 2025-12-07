// lib/model/today_task_model.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Tag {
  final String name;
  final Color backgroundColor;
  final Color textColor;

  const Tag({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
  });

  Map<String, dynamic> toJson() => {"name": name};

  factory Tag.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim();
    return Tag(
      name: name?.isNotEmpty == true ? name! : 'Tag',
      backgroundColor: const Color(0xFFE0E0E0),
      textColor: Colors.black87,
    );
  }
}

class TaskReminder {
  final int timeBefore; // minutes
  final List<String> types;

  const TaskReminder({
    required this.timeBefore,
    this.types = const ["notification"],
  });

  Map<String, dynamic> toJson() => {
        "time_before": timeBefore,
        "types": types,
      };

  factory TaskReminder.fromJson(Map<String, dynamic> json) {
    final types = (json['types'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        ["notification"];

    final timeBefore = (json['time_before'] as num?)?.toInt() ?? 0;

    return TaskReminder(
      timeBefore: timeBefore,
      types: types,
    );
  }

  bool get shouldCall => types.contains('call');
  bool get hasNotification => types.contains('notification');
}

class Task {
  final String id;
  String title;
  String description;
  DateTime startTime;     // ← LOCAL time (for display)
  DateTime? endTime;      // ← LOCAL time (can be null)
  final Duration duration;
  List<Tag> tags;
  List<TaskReminder> reminders;
  bool isCompleted;

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.startTime,
    this.endTime,
    Duration? duration,
    List<Tag>? tags,
    List<TaskReminder>? reminders,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        duration = duration ?? const Duration(hours: 1),
        tags = tags ?? [],
        reminders = reminders ?? [];

  // ────────────────────── SEND TO SERVER → UTC + 'Z' ──────────────────────
  Map<String, dynamic> toJson() {
    return {
      "title": title.trim().isEmpty ? "Untitled Task" : title.trim(),
      "description": description,
      "start_time": startTime.toUtc().toIso8601String(),     // 2025-12-07T23:20:00Z
      "end_time": endTime?.toUtc().toIso8601String(),
      "tags": tags.map((t) => t.name).toList(),
      "reminders": reminders.map((r) => r.toJson()).toList(),
      "completed": isCompleted,
    };
  }

  // ────────────────────── RECEIVE FROM SERVER → UTC → LOCAL ──────────────────────
  factory Task.fromJson(Map<String, dynamic> json) {
    // Parse UTC strings
    final startUtc = DateTime.tryParse(json['start_time'] ?? '');
    final endUtc = DateTime.tryParse(json['end_time'] ?? '');

    // Convert to local time for display
    final startTime = startUtc?.toLocal() ?? DateTime.now().toLocal();
    final endTime = endUtc?.toLocal();

    // Title & description
    final title = (json['title'] as String?)?.trim();
    final description = json['description'] as String? ?? '';

    // Tags
    final List<Tag> tags = [];
    final tagList = json['tags'] as List<dynamic>?;
    if (tagList != null) {
      for (var item in tagList) {
        if (item is String && item.toString().trim().isNotEmpty) {
          tags.add(Tag(
            name: item.toString().trim(),
            backgroundColor: const Color(0xFFE0E0E0),
            textColor: Colors.black87,
          ));
        }
      }
    }

    // Reminders
    final List<TaskReminder> reminders = [];
    final reminderList = json['reminders'] as List<dynamic>?;
    if (reminderList != null) {
      for (var item in reminderList) {
        if (item is Map<String, dynamic>) {
          try {
            reminders.add(TaskReminder.fromJson(item));
          } catch (e) {
            debugPrint("Invalid reminder: $e");
          }
        }
      }
    }

    return Task(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: title?.isNotEmpty == true ? title! : "Untitled Task",
      description: description,
      startTime: startTime,
      endTime: endTime,
      duration: endTime != null
          ? endTime.difference(startTime)
          : const Duration(hours: 1),
      tags: tags,
      reminders: reminders,
      isCompleted: json['completed'] == true,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    List<Tag>? tags,
    List<TaskReminder>? reminders,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      reminders: reminders ?? this.reminders,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}