// lib/repository/auth_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';
import 'package:saytask/core/jwt_helper.dart';
import 'package:saytask/model/user_model.dart';

class AuthRepository {
  final String baseUrl = Urls.baseUrl;

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    final body = jsonEncode({
      'full_name': fullName,
      'email': email,
      'password': password,
    });

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);

      if (data.containsKey('access')) {
        final token = data['access'];
        await LocalStorageService.saveToken(token);
        return UserModel.fromJwt(JwtHelper.decode(token));
      }

      return UserModel(
        userId: data['id']?.toString() ?? "",
        fullName: data['full_name'] ?? fullName,
        email: data['email'] ?? email,
      );
    }

    throw _handleError(res, "Registration failed");
  }

  Future<UserModel> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/token/');
    final body = jsonEncode({'email': email, 'password': password});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data.containsKey('access')) {
        final token = data['access'];
        await LocalStorageService.saveToken(token);
        return UserModel.fromJwt(JwtHelper.decode(token));
      }

      throw Exception("Login successful but access token missing");
    }

    throw _handleError(res, "Login failed");
  }

  Future<void> logout() async {
    await LocalStorageService.clear();
  }

  Future<UserModel> signInWithGoogle({required String idToken}) async {
    final url = Uri.parse('$baseUrl/auth/google-signin/');
    final body = jsonEncode({'id_token': idToken});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data.containsKey('access')) {
        final token = data['access'];
        await LocalStorageService.saveToken(token);
        return UserModel.fromJwt(JwtHelper.decode(token));
      }

      throw Exception("Google sign-in successful but access token missing");
    }

    throw _handleError(res, "Google sign-in failed");
  }


Future<UserModel> signInWithApple({required String identity_token}) async {
    final url = Uri.parse('$baseUrl/auth/apple-signin/');
    final body = jsonEncode({'identity_token': identity_token});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data.containsKey('access')) {
        final token = data['access'];
        await LocalStorageService.saveToken(token);
        return UserModel.fromJwt(JwtHelper.decode(token));
      }

      throw Exception("Apple sign-in successful but access token missing");
    }

    throw _handleError(res, "Apple sign-in failed");
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password/');
    final body = jsonEncode({'email': email});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw _handleError(res, "Failed to send OTP");
  }

  Future<Map<String, dynamic>> verifyResetOtp({
    required String token,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-reset-otp/');
    final body = jsonEncode({'token': token, 'otp': otp});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw _handleError(res, "OTP verification failed");
  }

  Future<bool> setNewPassword({
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/set-new-password/');
    final body = jsonEncode({'token': token, 'new_password': newPassword});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) return true;

    throw _handleError(res, "Reset password failed");
  }

  Future<Map<String, dynamic>> resendOtp(String token) async {
    final url = Uri.parse('$baseUrl/auth/resend-otp/');
    final body = jsonEncode({'token': token});

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _handleError(res, "Resend OTP failed");
  }

  Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  final token = LocalStorageService.token;
  if (token == null) {
    debugPrint("changePassword() ERROR: No token found");
    throw Exception("Not authenticated");
  }

  debugPrint("changePassword() → Sending request...");
  debugPrint("Token: ${token.substring(0, 20)}...");
  debugPrint("Current password: $currentPassword");
  debugPrint("New password: $newPassword");

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "current_password": currentPassword,
        "new_password": newPassword,
      }),
    );

    debugPrint("changePassword() RESPONSE:");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      debugPrint("PASSWORD CHANGED SUCCESSFULLY!");
      return;
    } else {
      final error = json.decode(response.body);
      final msg = error['message'] ?? error['error'] ?? "Unknown error";
      debugPrint("changePassword() FAILED: $msg");
      throw Exception(msg);
    }
  } catch (e) {
    debugPrint("changePassword() EXCEPTION: $e");
    rethrow;   
  }
}

  Exception _handleError(http.Response res, String defaultMsg) {
    try {
      final json = jsonDecode(res.body);
      if (json is Map && json.containsKey("detail")) {
        return Exception(json["detail"]);
      }
      if (json is Map && json.containsKey("message")) {
        return Exception(json["message"]);
      }
    } catch (_) {}

    return Exception("$defaultMsg (Code: ${res.statusCode})");
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    final url = Uri.parse('$baseUrl/auth/profile/');
    final token = LocalStorageService.token;

    if (token == null) throw Exception("No access token found");
    Map<String, dynamic> body = {};

    if (updatedUser.fullName.isNotEmpty) {
      body["first_name"] = updatedUser.fullName;
    }
    if (updatedUser.gender != null && updatedUser.gender!.isNotEmpty) {
      body["gender"] = updatedUser.gender;
    }
    if (updatedUser.dateOfBirth != null &&
        updatedUser.dateOfBirth!.isNotEmpty) {
      body["birth_date"] = updatedUser.dateOfBirth;
    }
    if (updatedUser.country != null && updatedUser.country!.isNotEmpty) {
      body["country"] = updatedUser.country;
    }
    if (updatedUser.phoneNumber != null &&
        updatedUser.phoneNumber!.isNotEmpty) {
      body["phone_number"] = updatedUser.phoneNumber;
    }

    body["notifications_enabled"] = updatedUser.notificationsEnabled;

    print("Sending profile update: $body");

    final res = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print("Response: ${res.statusCode} ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      return;
    }

    throw _handleError(res, "Failed to update profile");
  }


  Future<void> updateProfileNotifications(bool enabled) async {
  final token = LocalStorageService.token;
  if (token == null) throw Exception("No authentication token");

  final response = await http.patch(
    Uri.parse('$baseUrl/auth/profile/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "notifications_enabled": enabled.toString(), // API expects string "true"/"false"
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update notifications: ${response.body}');
  }
}
}
