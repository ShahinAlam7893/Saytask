import 'package:flutter/material.dart';

class Task {
  final String id;
  String title;
  String description;
  DateTime startTime;
  final Duration duration;
  final List<Tag> tags;
  List<String> reminders;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.duration,
    required this.tags,
    this.reminders = const [],
  });
}

class Tag {
  final String name;
  final Color backgroundColor;
  final Color textColor;

  Tag({required this.name, required this.backgroundColor, required this.textColor});
}