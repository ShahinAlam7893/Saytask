// lib/model/task_model.dart

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
    return Tag(
      name: json['name'] ?? 'unknown',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }
}

class Task {
  final String id;
  String title;
  String description;
  DateTime startTime;
  DateTime? endTime;
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
    List<TaskReminder> reminders = const [],
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        duration = duration ?? const Duration(hours: 1),
        tags = tags ?? [],
        reminders = reminders;

  // Auto-complete check
  bool shouldBeCompleted() {
    if (endTime == null) return false;
    return DateTime.now().isAfter(endTime!);
  }

  // Convert to API format
  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> reminderList = reminders.map((r) => r.toJson()).toList();

    return {
      "title": title,
      "description": description,
      "start_time": startTime.toUtc().toIso8601String(),
      "end_time": endTime?.toUtc().toIso8601String(),
      "tags": tags.map((t) => t.name).toList(),
      "reminders": reminderList,
      "completed": isCompleted,
    };
  }

  // Create from API response
  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parsedEndTime;
    if (json['end_time'] != null) {
      parsedEndTime = DateTime.parse(json['end_time']);
    }

    final reminderJson = json['reminders'] as List<dynamic>? ?? [];
    final List<TaskReminder> reminders = reminderJson
        .map((r) => TaskReminder.fromJson(r as Map<String, dynamic>))
        .toList();

    final tagList = (json['tags'] as List<dynamic>?) ?? [];
    final List<Tag> tags = tagList
        .map((t) => Tag(
              name: t.toString(),
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            ))
        .toList();

    return Task(
      id: json['id'] as String,
      title: json['title'] ?? 'Untitled Task',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: parsedEndTime,
      tags: tags,
      reminders: reminders,
      isCompleted: json['completed'] == true,
    );
  }

  // For editing
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

class TaskReminder {
  final int timeBefore; // minutes
  final List<String> types; // ["notification"], ["notification", "call"]

  TaskReminder({
    required this.timeBefore,
    this.types = const ["notification"],
  });

  Map<String, dynamic> toJson() => {
        "time_before": timeBefore,
        "types": types,
      };

  factory TaskReminder.fromJson(Map<String, dynamic> json) {
    final types = (json['types'] as List<dynamic>?)?.cast<String>() ?? ["notification"];
    return TaskReminder(
      timeBefore: json['time_before'] ?? 0,
      types: types,
    );
  }

  bool get shouldCall => types.contains('call');
}