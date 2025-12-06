// lib/service/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/service/local_storage_service.dart';
import 'package:saytask/model/event_model.dart';


class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

Future<List<Event>> fetchEvents() async {
  final token = await _getToken();
  if (token == null) throw Exception("No token");

  final url = Uri.parse('${Urls.baseUrl}/actions/events/');
  debugPrint("Calling API: $url");
  debugPrint("With token: ${token.substring(0, 20)}...");

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  debugPrint("Status Code: ${response.statusCode}");
  debugPrint("Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    debugPrint("Full JSON: $data");

    if (data is! Map<String, dynamic>) {
      debugPrint("ERROR: Response is not a JSON object");
      return [];
    }

    final eventList = data['events'] as List<dynamic>? ?? [];
    debugPrint("Found ${eventList.length} events in 'events' key");

    return eventList.map((e) {
      if (e is! Map<String, dynamic>) {
        debugPrint("Skipping invalid event: $e");
        return null;
      }
      return Event.fromJson(e);
    }).whereType<Event>().toList();
  }

  debugPrint("HTTP Error: ${response.statusCode} ${response.body}");
  throw Exception("Failed: ${response.statusCode}");
}
  Future<List<Task>> fetchTasks() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Urls.baseUrl}/actions/tasks/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['tasks'] as List)
          .map((json) => Task.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load tasks');
  }
}