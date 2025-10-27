import 'package:flutter/material.dart';

class Task {
  final String id;
  String title;
  String description;
  DateTime startTime;
  final Duration duration;
  final List<Tag> tags;
  List<String> reminders;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.duration,
    required this.tags,
    this.reminders = const [],
    this.isCompleted = false,
  });

  // Check if task should be auto-completed
  bool shouldBeCompleted() {
    final now = DateTime.now();
    final endTime = startTime.add(duration);
    return now.isAfter(endTime);
  }
}

class Tag {
  final String name;
  final Color backgroundColor;
  final Color textColor;

  Tag({required this.name, required this.backgroundColor, required this.textColor});
}