// lib/repository/reminder_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';

class ReminderService {
  /// Triggers the backend test-call API (sends FCM VoIP notification → call UI + TTS)
  static Future<bool> triggerReminderCall({
    required String message,
    String? title, // optional, for logging
  }) async {
    final token = LocalStorageService.token;
    if (token == null) {
      print("No auth token - cannot trigger reminder call");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${Urls.baseUrl}/actions/test-call/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Reminder call triggered successfully → $message");
        final data = jsonDecode(response.body);
        print("API Response: $data");
        return true;
      } else {
        print("Failed to trigger call: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error calling test-call API: $e");
      return false;
    }
  }
}