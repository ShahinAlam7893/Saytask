import 'package:flutter/material.dart';

class Event {
  final String title;
  final String location;
  final TimeOfDay time;
  final DateTime date;
  final String description;
  final int reminderMinutes; // e.g., 15 for "15 minutes before"

  Event({
    required this.title,
    required this.location,
    required this.time,
    required this.date,
    this.description = '',
    this.reminderMinutes = 15,
  });
}
