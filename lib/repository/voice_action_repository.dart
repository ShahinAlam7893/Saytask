// lib/repository/voice_action_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
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
      Uri.parse('$baseUrl/actions/classify/'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({"text": text.trim()}),
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
        "summarized": {"summary": "", "points": []}
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception("Failed to save note");
  }
}