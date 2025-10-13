// providers/calendar_provider.dart
import 'package:flutter/material.dart';
import 'dart:collection';

import 'package:saytask/model/event_model.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  final Map<DateTime, List<Event>> _events = LinkedHashMap<DateTime, List<Event>>(
    equals: (a, b) => a.isAtSameMomentAs(b),
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  )..addAll({
    //date format year-month-day
    DateTime.utc(2025, 10, 11): [
      Event(title: 'Meeting with Gabriel Boss', location: 'Zoom meeting', time: const TimeOfDay(hour: 06, minute: 00), date: DateTime(2025, 10, 11),),
    ],
    DateTime.utc(2025, 10, 8): [
      Event(title: 'Coffee with Shinchan', location: 'Caffe Cristal', time: const TimeOfDay(hour: 10, minute: 0),date: DateTime(2025, 10, 8),),
      Event(title: 'Workout', location: 'Fit Health', time: const TimeOfDay(hour: 20, minute: 0), date: DateTime(2025, 10, 8),),
    ],
  });

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;

  List<Event> get selectedDayEvents => _events[DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day)] ?? [];

  bool hasEvents(DateTime day) {
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _events.containsKey(dateOnly);
  }

  // *** ADD THIS METHOD ***
  // This public method allows setting the date from the UI
  void setInitialDate(DateTime date) {
    _focusedDate = date;
    _selectedDate = date;
    // We don't call notifyListeners() here because it will be called
    // in the widget's build method for the first time.
  }

  void selectDate(DateTime newDate) {
    if (!DateUtils.isSameDay(_selectedDate, newDate)) {
      _selectedDate = newDate;
      notifyListeners();
    }
  }

  void previousMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, _focusedDate.day);
    notifyListeners();
  }

  void nextMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, _focusedDate.day);
    notifyListeners();
  }
}