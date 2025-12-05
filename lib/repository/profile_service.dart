import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';

class ProfileService {
  static const String baseUrl = Urls.baseUrl;

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
  }) async {
    final token = await _getToken();

    if (token == null) {
      print("[UPDATE PROFILE] ❌ No token found");
      throw Exception("No access token. Please login again.");
    }

    final url = Uri.parse("$baseUrl/auth/profile/");

    final body = {
      "full_name": fullName,
      "email": email,
    };

    print("---- UPDATE PROFILE API ----");
    print("URL: $url");
    print("Token: Bearer ${token.substring(0, 12)}...");
    print("Request Body: $body");
    print("-----------------------------");

    final res = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("[UPDATE PROFILE] STATUS: ${res.statusCode}");
    print("[UPDATE PROFILE] RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      print("[UPDATE PROFILE] ✅ Success");
      return true;
    }

    print("[UPDATE PROFILE] ❌ Failed");
    throw Exception("Failed to update profile → ${res.statusCode}");
  }
}
