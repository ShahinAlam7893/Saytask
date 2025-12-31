// lib/utils/schedule_utils.dart

import 'package:intl/intl.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/model/today_task_model.dart';

bool isToday(DateTime? date) {
  if (date == null) return false;
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

DateTime normalizeDate(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

DateTime getStartTime(dynamic item) {
  if (item is Task) return item.startTime;
  if (item is Event) return item.eventDateTime ?? DateTime.now();
  return DateTime.now();
}

DateTime? getEndTime(dynamic item) {
  if (item is Task) return item.endTime;
  if (item is Event) {
    final start = item.eventDateTime;
    return start != null ? start.add(const Duration(hours: 1)) : null;
  }
  return null;
}

Duration getDuration(dynamic item) {
  if (item is Task) return item.duration;
  if (item is Event) return const Duration(hours: 1);
  return const Duration(hours: 1);
}

String getTitle(dynamic item) {
  if (item is Task) return item.title;
  if (item is Event) return item.title;
  return 'Untitled';
}

String getDescription(dynamic item) {
  if (item is Task) return item.description;
  if (item is Event) return item.description;
  return '';
}

bool isCompleted(dynamic item) => item is Task && item.isCompleted;

String formatTime(DateTime date) => DateFormat('h:mm a').format(date);