import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';

class ReminderService {
  static Future<bool> triggerTestReminderCall({
    required String message,
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

      if (response.statusCode == 200) {
        print("Test reminder call triggered successfully");
        final data = jsonDecode(response.body);
        print("Response: $data");
        return true;
      } else {
        print("Failed to trigger test call: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error triggering test call: $e");
      return false;
    }
  }
}