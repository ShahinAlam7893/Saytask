import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/model/plan_model.dart';
import 'package:saytask/service/local_storage_service.dart';

class PlanService {
  static const String baseUrl = Urls.baseUrl;

  Future<String?> _getToken() async {
    await LocalStorageService.init();
    return LocalStorageService.token;
  }

  Future<List<Plan>> getPlans() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("No access token found. Please login again.");
    }

    final url = Uri.parse("$baseUrl/subscription/plans/");

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      List results = decoded["results"] ?? [];

      return results.map((p) => Plan.fromJson(p)).toList();
    } else {
      throw Exception("Failed to load plans: ${res.statusCode} ${res.body}");
    }
  }

  Future<String> checkout(String planId, String billingInterval) async {
    final token = await _getToken();

    if (token == null) {
      print("❌ ERROR: No access token found");
      throw Exception("No access token found. Please login again.");
    }

    final url = Uri.parse("$baseUrl/subscription/checkout/");
    print("\n===== 📡 CHECKOUT API CALL =====");
    print("➡️ URL: $url");
    print("➡️ Headers: Authorization: Bearer $token");
    print("➡️ Sending data:");
    print("   - plan_id: $planId");
    print("   - billing_interval: $billingInterval");

    final res = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "plan_id": planId,
        "billing_interval": billingInterval,
      }),
    );

    print("⬅️ STATUS CODE: ${res.statusCode}");
    print("⬅️ RAW RESPONSE: ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = json.decode(res.body);

      print("📦 Decoded JSON: $decoded");

      final checkoutUrl = decoded["checkout_url"];
      print("🔗 Checkout URL = $checkoutUrl");

      if (checkoutUrl == null || checkoutUrl is! String) {
        print("❌ Invalid checkout URL received");
        throw Exception("Invalid checkout URL received");
      }

      print("✅ CHECKOUT SUCCESS — redirecting to payment link");
      return checkoutUrl;
    } else {
      final decoded = json.decode(res.body);
      // Change from "message" to "detail" to match your API response
      final message =
          decoded["detail"] ?? decoded["message"] ?? "Unknown error";

      print("❌ Checkout failed: ${res.statusCode} - ${res.body}");
      throw Exception(message);
    }
  }
}
