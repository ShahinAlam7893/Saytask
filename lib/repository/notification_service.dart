// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';
import '../utils/routes/routes.dart'; // for router

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important Notifications',
    description: 'Used for task reminders and alerts',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    // Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _handlePayload(jsonDecode(response.payload!));
        }
      },
    );

    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(message.data);
    });

    // Handle tap when app was terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () {
        _handlePayload(initialMessage.data);
      });
    }
  }

  static void _handlePayload(Map<String, dynamic> data) {
    print("Notification tapped: $data");

    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type']?.toString();
    final id = data['id']?.toString();
    final screen = data['screen']?.toString();

    if (type == 'task' && id != null) {
      context.go('/task-details/');
    } else if (type == 'note' && id != null) {
      context.go('/note-details/');
    } else if (type == 'event' && id != null) {
      context.go('/event-details/');
    } else if (screen == 'home') {
      context.go('/home');
    } else if (screen == 'notes') {
      context.go('/notes');
    } else if (screen == 'calendar') {
      context.go('/calendar');
    } else {
      context.go('/home');
    }
  }

  static Future<void> sendFcmTokenToBackend() async {
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
        // SUCCESS → PRINT THE TOKEN IN TERMINAL
        print("FCM TOKEN SUCCESSFULLY SENT TO BACKEND");
        print("FCM Token: $fcmToken");
        print("=" * 60);
      } else {
        print("Failed to send FCM token: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error sending FCM token: $e");
    }

    // Auto-resend on token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM Token refreshed! Resending to backend...");
      await sendFcmTokenToBackend(); // This will print again on success
    });
  }
}