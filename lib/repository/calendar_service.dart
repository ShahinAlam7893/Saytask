// lib/providers/calendar_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:collection';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/service/api_service.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  List<Event> _allEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Map<DateTime, List<Event>> _eventsByDate = LinkedHashMap<DateTime, List<Event>>(
    equals: (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  // ────────────────────── Getters ──────────────────────
  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<Event> get selectedDayEvents {
    final key = _normalizeDate(_selectedDate);
    final events = _eventsByDate[key] ?? [];
    debugPrint("selectedDayEvents for ${DateFormat('yyyy-MM-dd').format(_selectedDate)} → ${events.length} events");
    return events;
  }

  List<Event> getEventsForDate(DateTime date) {
    final key = _normalizeDate(date);
    final events = _eventsByDate[key] ?? [];
    debugPrint("getEventsForDate ${DateFormat('yyyy-MM-dd').format(date)} → ${events.length} events");
    return events;
  }

  bool hasEvents(DateTime day) {
    final key = _normalizeDate(day);
    final has = _eventsByDate[key]?.isNotEmpty ?? false;
    if (has) debugPrint("hasEvents: YES on ${DateFormat('yyyy-MM-dd').format(day)}");
    return has;
  }

  // ────────────────────── Load from Backend ──────────────────────
  Future<void> loadEvents() async {
    debugPrint("loadEvents() called");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Fetching events from API...");
      final events = await ApiService().fetchEvents();

      debugPrint("Raw API returned ${events.length} events");

      _allEvents = events;

      for (var e in events) {
        debugPrint("Event: '${e.title}' → DateTime: ${e.eventDateTime} (local)");
        debugPrint("  UTC: ${e.eventDateTime?.toUtc()}");
      }

      _rebuildEventsMap();

      debugPrint("Events map has ${_eventsByDate.length} dates with events");
      _eventsByDate.keys.forEach((key) {
        debugPrint("  Date ${DateFormat('yyyy-MM-dd').format(key.toLocal())} → ${_eventsByDate[key]!.length} events");
      });
    } catch (e, stack) {
      _errorMessage = "Failed to load events";
      debugPrint("ERROR loading events: $e");
      debugPrint(stack.toString());
    } finally {
      _isLoading = false;
      debugPrint("loadEvents() finished. isLoading = false");
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    final oldDate = _selectedDate;
    _selectedDate = date;
    debugPrint("selectDate: $oldDate → $date");
    notifyListeners();
  }

  void previousMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    debugPrint("previousMonth → $_focusedDate");
    notifyListeners();
  }

  void nextMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    debugPrint("nextMonth → $_focusedDate");
    notifyListeners();
  }

  void addEvent(Event event) {
    debugPrint("addEvent: ${event.title} on ${event.eventDateTime}");
    _allEvents.add(event);
    _rebuildEventsMap();
    notifyListeners();
  }

  void updateEvent(Event oldEvent, Event newEvent) {
    final index = _allEvents.indexWhere((e) => e.id == oldEvent.id);
    if (index != -1) {
      debugPrint("updateEvent: ${oldEvent.title} → ${newEvent.title}");
      _allEvents[index] = newEvent;
      _rebuildEventsMap();
      notifyListeners();
    }
  }

  void removeEvent(Event event) {
    debugPrint("removeEvent: ${event.title}");
    _allEvents.removeWhere((e) => e.id == event.id);
    _rebuildEventsMap();
    notifyListeners();
  }

  // ────────────────────── Helpers ──────────────────────
  DateTime _normalizeDate(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return normalized;
  }

  void _rebuildEventsMap() {
    debugPrint("_rebuildEventsMap() called");
    _eventsByDate.clear();
    for (final event in _allEvents) {
      if (event.eventDateTime == null) {
        debugPrint("SKIPPING event with null eventDateTime: ${event.title}");
        continue;
      }
      final key = _normalizeDate(event.eventDateTime!);
      _eventsByDate.putIfAbsent(key, () => []).add(event);
    }
    debugPrint("_rebuildEventsMap() done. ${_eventsByDate.length} dates populated");
  }
}