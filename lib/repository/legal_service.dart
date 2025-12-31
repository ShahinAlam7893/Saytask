// repository/legal_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';

class LegalService {
  static const String baseUrl = Urls.baseUrl;

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

  Future<String> getTerms() async {
    final token = await _getToken();
    if (token == null) throw Exception("Authentication required");

    final url = Uri.parse("$baseUrl/admin-panel/legal/terms/");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'] as String;
    } else {
      throw Exception("Failed to load Terms & Conditions");
    }
  }

  Future<String> getPrivacyPolicy() async {
    final token = await _getToken();
    if (token == null) throw Exception("Authentication required");

    final url = Uri.parse("$baseUrl/admin-panel/legal/privacy/");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'] as String;
    } else {
      throw Exception("Failed to load Privacy Policy");
    }
  }
}