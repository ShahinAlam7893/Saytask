import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

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
    return Tag(
      name: (json['name'] as String?)?.trim().isNotEmpty == true ? json['name'] : 'Tag',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }
}

class TaskReminder {
  final int timeBefore;
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
            .toList()
        ?? ["notification"];

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
  DateTime startTime;
  DateTime endTime; // ← Now required — no ?
  final Duration duration;
  List<Tag> tags;
  List<TaskReminder> reminders;
  bool isCompleted;

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.startTime,
    DateTime? endTime,
    Duration? duration,
    List<Tag>? tags,
    List<TaskReminder>? reminders,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        duration = duration ?? const Duration(hours: 1),
        endTime = endTime ?? startTime.add(duration ?? const Duration(hours: 1)),
        tags = tags ?? [],
        reminders = reminders ?? [];

  // ────────────────────── TO JSON (Send to server in UTC without Z) ──────────────────────
  Map<String, dynamic> toJson() {
    return {
      "title": title.trim().isEmpty ? "Untitled Task" : title.trim(),
      "description": description,
      "start_time": DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(startTime.toUtc()),
      "end_time": DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(endTime.toUtc()),
      "tags": tags.map((t) => t.name).toList(),
      "reminders": reminders.map((r) => r.toJson()).toList(),
      "completed": isCompleted,
    };
  }

  // ────────────────────── FROM JSON (Receive from server — UTC → Local) ──────────────────────
  factory Task.fromJson(Map<String, dynamic> json) {
    // Parse start_time (UTC → Local)
    DateTime startTime = DateTime.now();
    if (json['start_time'] != null) {
      final parsed = DateTime.tryParse(json['start_time']);
      if (parsed != null) {
        startTime = parsed.toLocal();
      }
    }

    // Parse end_time (UTC → Local)
    DateTime endTime = startTime.add(const Duration(hours: 1));
    if (json['end_time'] != null) {
      final parsed = DateTime.tryParse(json['end_time']);
      if (parsed != null) {
        endTime = parsed.toLocal();
      }
    }

    // Safe string parsing
    final String title = (json['title'] as String?)?.trim().isNotEmpty == true
        ? json['title'].trim()
        : "Untitled Task";

    final String description = (json['description'] as String?) ?? '';

    // Parse tags safely
    final List<Tag> tags = <Tag>[];
    final tagList = json['tags'] as List<dynamic>?;
    if (tagList != null) {
      for (var item in tagList) {
        if (item is String && item.trim().isNotEmpty) {
          tags.add(Tag(
            name: item.trim(),
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ));
        }
      }
    }

    // Parse reminders safely
    final List<TaskReminder> reminders = <TaskReminder>[];
    final reminderList = json['reminders'] as List<dynamic>?;
    if (reminderList != null) {
      for (var item in reminderList) {
        if (item is Map<String, dynamic>) {
          try {
            reminders.add(TaskReminder.fromJson(item));
          } catch (e) {
            // Skip invalid reminder
          }
        }
      }
    }

    return Task(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      tags: tags,
      reminders: reminders,
      isCompleted: json['completed'] == true || json['completed'] == 1,
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
    final newStartTime = startTime ?? this.startTime;
    final newDuration = duration ?? this.duration;
    final newEndTime = endTime ?? newStartTime.add(newDuration);

    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: newStartTime,
      endTime: newEndTime,
      duration: newDuration,
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