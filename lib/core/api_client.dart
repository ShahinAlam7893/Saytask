import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';

class ApiClient {
  final baseUrl = Urls.baseUrl;

  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(baseUrl + url),
      body: jsonEncode(body),
      headers: {"Content-Type": "application/json"},
    );

    return jsonDecode(response.body);
  }
}
