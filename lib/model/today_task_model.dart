import 'package:flutter/material.dart';

class Task {
  final String id;
  String title;
  DateTime startTime;
  final Duration duration;
  final List<Tag> tags;

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.duration,
    required this.tags,
  });
}

class Tag {
  final String name;
  final Color backgroundColor;
  final Color textColor;

  Tag({required this.name, required this.backgroundColor, required this.textColor});
}