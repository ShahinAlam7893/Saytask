import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Add uuid package for generating unique IDs

class Event {
  final String id; // Add unique ID
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final int reminderMinutes;

  Event({
    String? id, // Allow ID to be optional for creation
    required this.title,
    this.description = '',
    this.location = '',
    required this.date,
    required this.time,
    this.reminderMinutes = 0,
  }) : id = id ?? const Uuid().v4(); // Generate a unique ID if not provided

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Event &&
              runtimeType == other.runtimeType &&
              id == other.id; // Use ID for equality

  @override
  int get hashCode => id.hashCode; // Use ID for hashCode
}