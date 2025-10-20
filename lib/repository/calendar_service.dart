// providers/calendar_provider.dart
import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:saytask/model/event_model.dart';
import 'package:uuid/uuid.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  final Map<DateTime, List<Event>> _events = LinkedHashMap<DateTime, List<Event>>(
    equals: (a, b) => a.isAtSameMomentAs(b),
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  )..addAll({
    DateTime.utc(2025, 10, 11): [
      Event(
        id: const Uuid().v4(),
        title: 'Meeting with Gabriel Boss',
        location: 'Zoom meeting',
        time: const TimeOfDay(hour: 06, minute: 00),
        date: DateTime(2025, 10, 11),
      ),
    ],
    DateTime.utc(2025, 10, 8): [
      Event(
        id: const Uuid().v4(),
        title: 'Coffee with Shinchan',
        location: 'Caffe Cristal',
        time: const TimeOfDay(hour: 10, minute: 0),
        date: DateTime(2025, 10, 8),
      ),
      Event(
        id: const Uuid().v4(),
        title: 'Workout',
        location: 'Fit Health',
        time: const TimeOfDay(hour: 20, minute: 0),
        date: DateTime(2025, 10, 8),
      ),
    ],
  });

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;

  List<Event> get selectedDayEvents => _events[DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day)] ?? [];

  // New method to get events for a specific date
  List<Event> getEventsForDate(DateTime date) {
    final dateKey = DateTime.utc(date.year, date.month, date.day);
    return _events[dateKey] ?? [];
  }

  bool hasEvents(DateTime day) {
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _events.containsKey(dateOnly);
  }

  void setInitialDate(DateTime date) {
    _focusedDate = date;
    _selectedDate = date;
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

  void updateEvent(Event oldEvent, Event newEvent) {
    final dateKey = DateTime.utc(oldEvent.date.year, oldEvent.date.month, oldEvent.date.day);
    final events = _events[dateKey];
    if (events != null) {
      final index = events.indexWhere((e) => e.id == oldEvent.id);
      if (index != -1) {
        events[index] = newEvent;
        if (!DateUtils.isSameDay(oldEvent.date, newEvent.date)) {
          events.removeAt(index);
          if (events.isEmpty) _events.remove(dateKey);
          final newDateKey = DateTime.utc(newEvent.date.year, newEvent.date.month, newEvent.date.day);
          _events.putIfAbsent(newDateKey, () => []).add(newEvent);
        }
        notifyListeners();
      }
    }
  }

  void removeEvent(Event event) {
    final dateKey = DateTime.utc(event.date.year, event.date.month, event.date.day);
    final events = _events[dateKey];
    if (events != null) {
      events.removeWhere((e) => e.id == event.id);
      if (events.isEmpty) _events.remove(dateKey);
      notifyListeners();
    }
  }

  void removeReminderFromEvent(Event event) {
    final dateKey = DateTime.utc(event.date.year, event.date.month, event.date.day);
    final events = _events[dateKey];
    if (events != null) {
      final index = events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        final updatedEvent = Event(
          id: event.id,
          title: event.title,
          description: event.description,
          location: event.location,
          date: event.date,
          time: event.time,
          reminderMinutes: 0,
        );
        events[index] = updatedEvent;
        notifyListeners();
      }
    }
  }
}