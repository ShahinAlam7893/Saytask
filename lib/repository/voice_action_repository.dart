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
    throw Exception("Failed to create event");
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
    throw Exception("Failed to create task");
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
    throw Exception("Failed to save note");
  }

  Future<void> saveVoiceAction(VoiceClassification classification) async {
    try {
      String getRealDate(String? input) {
        if (input == null)
          return DateTime.now().toIso8601String().split('T').first;
        final lower = input.toLowerCase().trim();
        final now = DateTime.now();
        if (lower == "today") {
          return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        } else if (lower == "tomorrow") {
          final t = now.add(const Duration(days: 1));
          return "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}";
        }
        return input;
      }

      final dateStr = getRealDate(classification.date);
      final timeStr = (classification.time ?? "10:00").padLeft(5, '0');
      final startTimeStr = "${dateStr}T${timeStr}:00Z";

      switch (classification.type) {
        case 'task':
          await createTask({
            "title": classification.title.trim().isEmpty
                ? "New Task"
                : classification.title.trim(),
            "description": classification.description?.trim() ?? "",
            "start_time": startTimeStr,
            "duration": 60,
            "tags": classification.tags ?? [],
            "reminders": classification.callMe
                ? [
                    {
                      "time_before": 10,
                      "types": ["notification", "call"],
                    },
                    {
                      "time_before": 30,
                      "types": ["notification"],
                    },
                  ]
                : [
                    {
                      "time_before": 30,
                      "types": ["notification"],
                    },
                  ],
            "completed": false,
          });
          break;

        case 'event':
          final endTimeStr = DateTime.parse(
            startTimeStr.replaceAll('Z', ''),
          ).add(const Duration(hours: 1)).toUtc().toIso8601String();
          await createEvent({
            "title": classification.title.trim().isEmpty
                ? "New Event"
                : classification.title.trim(),
            "description": classification.description?.trim() ?? "",
            "start_time": startTimeStr,
            "end_time": endTimeStr,
            "location": "",
          });
          break;

        case 'note':
        default:
          await createNote(classification.rawText);
          break;
      }
    } catch (e) {
      debugPrint("Save failed: $e");
      rethrow;
    }
  }
}
