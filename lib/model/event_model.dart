import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 

class Event {
  final String id; 
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final int reminderMinutes;

  Event({
    String? id, 
    required this.title,
    this.description = '',
    this.location = '',
    required this.date,
    required this.time,
    this.reminderMinutes = 0,
  }) : id = id ?? const Uuid().v4(); 

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Event &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode; 
}