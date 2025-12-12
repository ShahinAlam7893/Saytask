// lib/service/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/service/local_storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

  // ────────────────────── FETCH EVENTS ──────────────────────
  Future<List<Event>> fetchEvents() async {
    final token = await _getToken();
    if (token == null) throw Exception("No token");

    final url = Uri.parse('${Urls.baseUrl}/actions/events/');
    debugPrint("Calling API: $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final eventList = data['events'] as List<dynamic>? ?? [];

      return eventList
          .whereType<Map<String, dynamic>>()
          .map((e) => Event.fromJson(e))
          .toList();
    }

    throw Exception("Failed to load events: ${response.statusCode}");
  }

  // ────────────────────── FETCH TASKS ──────────────────────
  Future<List<Task>> fetchTasks() async {
    final token = await _getToken();
    if (token == null) throw Exception("No token");

    final response = await http.get(
      Uri.parse('${Urls.baseUrl}/actions/tasks/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final taskList = data['tasks'] as List<dynamic>? ?? [];

      return taskList
          .whereType<Map<String, dynamic>>()
          .map((json) => Task.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load tasks: ${response.statusCode}');
  }

  // ────────────────────── UPDATE TASK ON SERVER ──────────────────────
  Future<void> updateTaskOnServer(Task task) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("No token found for update");
        return;
      }

      final response = await http.put(
        Uri.parse('${Urls.baseUrl}/actions/tasks/${task.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(task.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint("Task ${task.id} updated on server************************");
      } else {
        debugPrint("Update failed: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("Update task error: $e");
    }
  }

  // ────────────────────── (Optional) DELETE TASK ──────────────────────
  Future<void> deleteTaskOnServer(String taskId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${Urls.baseUrl}/actions/tasks/$taskId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("Task $taskId deleted from server");
      } else {
        debugPrint("Delete failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Delete task error: $e");
    }
  }
}