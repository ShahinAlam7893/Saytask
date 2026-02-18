
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';

 Future<void> sendFcmTokenToBackend() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      print("FCM Token is null - cannot send");
      return;
    }

    final jwtToken = LocalStorageService.token;
    if (jwtToken == null) {
      print("User not logged in (no JWT token) - skipping FCM send");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Urls.baseUrl}/auth/device-token/'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("FCM TOKEN SUCCESSFULLY SENT TO BACKEND");
        print("FCM Token: $fcmToken");
        print("=" * 60);
      } else {
        print("Failed to send FCM token: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error sending FCM token: $e");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM Token refreshed! Resending to backend...");
      await sendFcmTokenToBackend();
    });
  }
