// lib/repository/calendar_service.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:collection';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/service/api_service.dart';
import 'package:saytask/utils/utils.dart';

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  List<Event> _allEvents = [];
  List<Task> _allTasks = [];
  List<Event> get allEvents => _allEvents;

  bool _isLoading = true;
  String? _errorMessage;

  final Map<DateTime, List<dynamic>> _itemsByDate = LinkedHashMap<DateTime, List<dynamic>>(
    equals: (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<dynamic> get selectedDayItems {
    final key = normalizeDate(_selectedDate);
    final items = List<dynamic>.from(_itemsByDate[key] ?? []);
    items.sort((a, b) => getStartTime(a).compareTo(getStartTime(b)));
    return items;
  }

  List<dynamic> getItemsForDate(DateTime date) {
    final key = normalizeDate(date);
    final items = List<dynamic>.from(_itemsByDate[key] ?? []);
    items.sort((a, b) => getStartTime(a).compareTo(getStartTime(b)));
    return items;
  }

  bool hasItems(DateTime day) {
    final key = normalizeDate(day);
    return _itemsByDate[key]?.isNotEmpty ?? false;
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final events = await ApiService().fetchEvents();
      final tasks = await ApiService().fetchTasks();

      _allEvents = events;
      _allTasks = tasks;

      _rebuildItemsMap();
    } catch (e) {
      _errorMessage = "Failed to load schedule";
      debugPrint("Load error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _rebuildItemsMap() {
    _itemsByDate.clear();

    for (final event in _allEvents) {
      final dateTime = event.eventDateTime;
      if (dateTime == null) continue;
      final key = normalizeDate(dateTime);
      _itemsByDate.putIfAbsent(key, () => []).add(event);
    }

    for (final task in _allTasks) {
      final key = normalizeDate(task.startTime);
      _itemsByDate.putIfAbsent(key, () => []).add(task);
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void previousMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    notifyListeners();
  }

  void addItem(dynamic item) {
    if (item is Event) _allEvents.add(item);
    if (item is Task) _allTasks.add(item);
    _rebuildItemsMap();
    notifyListeners();
  }

  // ────────────────────── UPDATE EVENT TIME (Drag & Drop) ──────────────────────
  Future<void> updateEventTime(String eventId, DateTime newTime) async {
    
    final index = _allEvents.indexWhere((e) => e.id == eventId);
    debugPrint("║ Event found at index: $index");
    
    if (index == -1) {
      return;
    }

    final oldEvent = _allEvents[index];
    debugPrint("║ Old event title: ${oldEvent.title}");
    debugPrint("║ Old event time: ${oldEvent.eventDateTime}");
    
    final updatedEvent = oldEvent.copyWith(eventDateTime: newTime);
    debugPrint("║ Updated event time: ${updatedEvent.eventDateTime}");

    // Optimistic update
    _allEvents[index] = updatedEvent;
    _rebuildItemsMap();
    notifyListeners();

    // Sync with server
    try {
      await ApiService().updateEventOnServer(updatedEvent);
    } catch (e, stackTrace) {

      
      // Rollback on error
      _allEvents[index] = oldEvent;
      _rebuildItemsMap();
      notifyListeners();
      rethrow;
    }
  }

  // ────────────────────── UPDATE EVENT (Full Edit) ──────────────────────
  Future<void> updateItem(dynamic oldItem, dynamic newItem) async {
    
    if (oldItem is Event && newItem is Event) {
      final index = _allEvents.indexWhere((e) => e.id == oldItem.id);
      if (index == -1) {
        return;
      }

      final previousEvent = _allEvents[index];

      _allEvents[index] = newItem;
      _rebuildItemsMap();
      notifyListeners();

      // Sync with server
      try {
        debugPrint("║ 🚀 Making API call...");
        final updatedFromServer = await ApiService().updateEventOnServer(newItem);
        
        _allEvents[index] = updatedFromServer;
        _rebuildItemsMap();
        notifyListeners();
      } catch (e, stackTrace) {
        
        // Rollback
        _allEvents[index] = previousEvent;
        _rebuildItemsMap();
        notifyListeners();
        
        rethrow;
      }
    } else if (oldItem is Task && newItem is Task) {

      final index = _allTasks.indexWhere((t) => t.id == oldItem.id);
      if (index != -1) {
        _allTasks[index] = newItem;
        _rebuildItemsMap();
        notifyListeners();
      }
    } else {

    }
  }

  // ────────────────────── DELETE EVENT ──────────────────────
  Future<void> removeItem(dynamic item) async {
    if (item is Event) {
      
      final removedEvent = item;
      final removedIndex = _allEvents.indexWhere((e) => e.id == item.id);
      debugPrint("║ Event index in list: $removedIndex");
      
      // Optimistic delete
      _allEvents.removeWhere((e) => e.id == item.id);
      _rebuildItemsMap();
      notifyListeners();
      // Sync with server
      try {
        await ApiService().deleteEventOnServer(item.id);
      } catch (e, stackTrace) {
        
        // Rollback
        _allEvents.add(removedEvent);
        _rebuildItemsMap();
        notifyListeners();
        rethrow;
      }
    } else if (item is Task) {
      debugPrint("📝 Deleting Task (local only)");
      _allTasks.removeWhere((t) => t.id == item.id);
      _rebuildItemsMap();
      notifyListeners();
    }
  }

  // ────────────────────── TOGGLE EVENT COMPLETION ──────────────────────
  Future<void> toggleEventCompletion(String eventId) async {
    
    final index = _allEvents.indexWhere((e) => e.id == eventId);
    debugPrint("║ Event found at index: $index");
    
    if (index == -1) {
      return;
    }

    final oldEvent = _allEvents[index];
    debugPrint("║ Current completion status: ${oldEvent.isCompleted}");
    
    final updatedEvent = oldEvent.copyWith(
      isCompleted: !oldEvent.isCompleted,
    );
    debugPrint("║ New completion status: ${updatedEvent.isCompleted}");

    // Optimistic update
    _allEvents[index] = updatedEvent;
    _rebuildItemsMap();
    notifyListeners();
    try {
      await ApiService().updateEventOnServer(updatedEvent);
    } catch (e, stackTrace) {

      
      // Rollback
      _allEvents[index] = oldEvent;
      _rebuildItemsMap();
      notifyListeners();
      
    }
  }
}






// // lib/providers/calendar_provider.dart

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:collection';
// import 'package:saytask/model/event_model.dart';
// import 'package:saytask/service/api_service.dart';

// class CalendarProvider extends ChangeNotifier {
//   DateTime _selectedDate = DateTime.now();
//   DateTime _focusedDate = DateTime.now();

//   List<Event> _allEvents = [];
//   bool _isLoading = true;
//   String? _errorMessage;

//   final Map<DateTime, List<Event>> _eventsByDate = LinkedHashMap<DateTime, List<Event>>(
//     equals: (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
//     hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
//   );

//   // ────────────────────── Getters ──────────────────────
//   DateTime get selectedDate => _selectedDate;
//   DateTime get focusedDate => _focusedDate;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   bool get hasError => _errorMessage != null;

//   List<Event> get selectedDayEvents {
//     final key = _normalizeDate(_selectedDate);
//     final events = _eventsByDate[key] ?? [];
//     debugPrint("selectedDayEvents for ${DateFormat('yyyy-MM-dd').format(_selectedDate)} → ${events.length} events");
//     return events;
//   }

//   List<Event> getEventsForDate(DateTime date) {
//     final key = _normalizeDate(date);
//     final events = _eventsByDate[key] ?? [];
//     debugPrint("getEventsForDate ${DateFormat('yyyy-MM-dd').format(date)} → ${events.length} events");
//     return events;
//   }

//   bool hasEvents(DateTime day) {
//     final key = _normalizeDate(day);
//     final has = _eventsByDate[key]?.isNotEmpty ?? false;
//     if (has) debugPrint("hasEvents: YES on ${DateFormat('yyyy-MM-dd').format(day)}");
//     return has;
//   }

//   // ────────────────────── Load from Backend ──────────────────────
//   Future<void> loadEvents() async {
//     debugPrint("loadEvents() called");
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
//     Future.microtask(() => notifyListeners());
//     try {
//       debugPrint("Fetching events from API...");
//       final events = await ApiService().fetchEvents();

//       debugPrint("Raw API returned ${events.length} events");

//       _allEvents = events;

//       for (var e in events) {
//         debugPrint("Event: '${e.title}' → DateTime: ${e.eventDateTime} (local)");
//         debugPrint("  UTC: ${e.eventDateTime?.toUtc()}");
//       }

//       _rebuildEventsMap();

//       debugPrint("Events map has ${_eventsByDate.length} dates with events");
//       _eventsByDate.keys.forEach((key) {
//         debugPrint("  Date ${DateFormat('yyyy-MM-dd').format(key.toLocal())} → ${_eventsByDate[key]!.length} events");
//       });
//     } catch (e, stack) {
//       _errorMessage = "Failed to load events";
//       debugPrint("ERROR loading events: $e");
//       debugPrint(stack.toString());
//     } finally {
//       _isLoading = false;
//       debugPrint("loadEvents() finished. isLoading = false");
//       notifyListeners();
//     }
//   }

//   void selectDate(DateTime date) {
//     final oldDate = _selectedDate;
//     _selectedDate = date;
//     debugPrint("selectDate: $oldDate → $date");
//     notifyListeners();
//   }

//   void previousMonth() {
//     _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
//     debugPrint("previousMonth → $_focusedDate");
//     notifyListeners();
//   }

//   void nextMonth() {
//     _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
//     debugPrint("nextMonth → $_focusedDate");
//     notifyListeners();
//   }

//   void addEvent(Event event) {
//     debugPrint("addEvent: ${event.title} on ${event.eventDateTime}");
//     _allEvents.add(event);
//     _rebuildEventsMap();
//     notifyListeners();
//   }

//   void updateEvent(Event oldEvent, Event newEvent) {
//     final index = _allEvents.indexWhere((e) => e.id == oldEvent.id);
//     if (index != -1) {
//       debugPrint("updateEvent: ${oldEvent.title} → ${newEvent.title}");
//       _allEvents[index] = newEvent;
//       _rebuildEventsMap();
//       notifyListeners();
//     }
//   }

//   void removeEvent(Event event) {
//     debugPrint("removeEvent: ${event.title}");
//     _allEvents.removeWhere((e) => e.id == event.id);
//     _rebuildEventsMap();
//     notifyListeners();
//   }

//   // ────────────────────── Helpers ──────────────────────
//   DateTime _normalizeDate(DateTime date) {
//     final normalized = DateTime.utc(date.year, date.month, date.day);
//     return normalized;
//   }

//   void _rebuildEventsMap() {
//     debugPrint("_rebuildEventsMap() called");
//     _eventsByDate.clear();
//     for (final event in _allEvents) {
//       if (event.eventDateTime == null) {
//         debugPrint("SKIPPING event with null eventDateTime: ${event.title}");
//         continue;
//       }
//       final key = _normalizeDate(event.eventDateTime!);
//       _eventsByDate.putIfAbsent(key, () => []).add(event);
//     }
//     debugPrint("_rebuildEventsMap() done. ${_eventsByDate.length} dates populated");
//   }
// }