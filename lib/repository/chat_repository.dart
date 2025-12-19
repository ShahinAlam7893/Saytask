
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart'; 

class ChatRepository {
  final String baseUrl = Urls.baseUrl;

  Future<Map<String, dynamic>> getChatHistory() async {
    final token = LocalStorageService.token;
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/history/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat history: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    final token = LocalStorageService.token;
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/chat/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> summarizeNote(String note) async {
    final token = LocalStorageService.token;
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/summarize-note/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'note': note}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to summarize note: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> classifyMessage(String message) async {
    final token = LocalStorageService.token;
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/classify/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to classify message: ${response.body}');
    }
  }
}