// lib/repository/voice_action_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/service/local_storage_service.dart';

class VoiceActionRepository {
  final String baseUrl = Urls.baseUrl;

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

  Future<Map<String, dynamic>> classifyVoiceInput(String text) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/classify/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({"message": text.trim()}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Classification failed: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/actions/events/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to create event: ${response.body}");
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/actions/tasks/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to create task: ${response.body}");
  }

  Future<Map<String, dynamic>> createNote(String text) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/actions/notes/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "title": "Voice Note",
        "original": text,
        "summarized": {"summary": "", "points": []},
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to save note: ${response.body}");
  }

  Future<void> saveVoiceAction(VoiceClassification classification) async {
    try {
      // CRITICAL FIX: Ensure date is never null
      final now = DateTime.now();
      final dateStr = _parseDate(classification.date);
      final timeStr = _parseTime(classification.time);
      
      // Build proper ISO 8601 UTC string
      final localDateTime = DateTime.parse('$dateStr $timeStr');
      final startTimeStr = localDateTime.toUtc().toIso8601String();

      debugPrint('Saving voice action:');
      debugPrint('  Type: ${classification.type}');
      debugPrint('  Date: $dateStr');
      debugPrint('  Time: $timeStr');
      debugPrint('  UTC: $startTimeStr');

      switch (classification.type) {
        case 'task':
          await createTask({
            "title": classification.title.trim().isEmpty ? "New Task" : classification.title.trim(),
            "description": classification.description?.trim() ?? "",
            "start_time": startTimeStr,
            "duration": 60,
            "tags": classification.tags ?? [],
            "reminders": _buildReminders(classification),
            "completed": false,
          });
          break;

        case 'event':
          final endTimeStr = localDateTime.add(const Duration(hours: 1)).toUtc().toIso8601String();
          await createEvent({
            "title": classification.title.trim().isEmpty ? "New Event" : classification.title.trim(),
            "description": classification.description?.trim() ?? "",
            "event_datetime": startTimeStr,
            "start_time": startTimeStr,
            "end_time": endTimeStr,
            "location_address": classification.location ?? "",
          });
          break;

        case 'note':
        default:
          await createNote(classification.rawText);
          break;
      }

      debugPrint('Voice action saved successfully!');
    } catch (e) {
      debugPrint("Save failed: $e");
      rethrow;
    }
  }

  // Parse date with fallback to current date
  String _parseDate(String? input) {
    if (input == null || input.isEmpty) {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    final lower = input.toLowerCase().trim();
    final now = DateTime.now();

    if (lower == "today") {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (lower == "tomorrow") {
      final tomorrow = now.add(const Duration(days: 1));
      return '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    }

    // Try parsing the input directly
    try {
      final parsed = DateTime.parse(input);
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // Fallback to current date
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  // Parse time with fallback to 1 hour from now
  String _parseTime(String? input) {
    if (input == null || input.isEmpty) {
      final nextHour = DateTime.now().add(const Duration(hours: 1));
      return '${nextHour.hour.toString().padLeft(2, '0')}:00:00';
    }

    // Ensure proper format
    try {
      final parts = input.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]).toString().padLeft(2, '0');
        final minute = int.parse(parts[1]).toString().padLeft(2, '0');
        return '$hour:$minute:00';
      }
    } catch (e) {
      debugPrint('Time parse error: $e');
    }

    // Fallback
    final nextHour = DateTime.now().add(const Duration(hours: 1));
    return '${nextHour.hour.toString().padLeft(2, '0')}:00:00';
  }

  // Build reminders array
  List<Map<String, dynamic>> _buildReminders(VoiceClassification classification) {
    final reminders = <Map<String, dynamic>>[];

    if (classification.callMe) {
      reminders.add({
        "time_before": 10,
        "types": ["notification", "call"],
      });
    }

    if (classification.reminder != "At time of event" && classification.reminder != "None") {
      final minutes = _reminderToMinutes(classification.reminder);
      if (minutes > 0) {
        reminders.add({
          "time_before": minutes,
          "types": ["notification"],
        });
      }
    }

    // Default reminder if none specified
    if (reminders.isEmpty) {
      reminders.add({
        "time_before": 30,
        "types": ["notification"],
      });
    }

    return reminders;
  }

  int _reminderToMinutes(String reminder) {
    final map = {
      "5 minutes before": 5,
      "10 minutes before": 10,
      "15 minutes before": 15,
      "30 minutes before": 30,
      "1 hour before": 60,
      "2 hours before": 120,
    };
    return map[reminder] ?? 0;
  }
}