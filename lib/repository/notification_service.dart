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
import 'package:saytask/utils/reminder_call_helper.dart';

import '../utils/routes/routes.dart'; // for router

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background FCM Message: ${message.messageId} | Data: ${message.data}");

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
    importance: Importance.max, // Raised to max for better visibility
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

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            _handlePayload(jsonDecode(response.payload!));
          } catch (e) {
            print("Payload decode error: $e");
          }
        }
      },
    );

    // Create high-priority Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // ────────────────────── Foreground FCM Handler ──────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
        "Foreground FCM → ID: ${message.messageId} | Data: ${message.data}",
      );

      // Handle special "reminder_call" type
      if (message.data['type'] == 'reminder_call') {
        final taskId =
            message.data['taskId']?.toString() ??
            'unknown-${DateTime.now().millisecondsSinceEpoch}';
        final title = message.data['title']?.toString() ?? 'SayTask Reminder';
        final reminderText =
            message.data['message']?.toString() ??
            'Time to complete your task!';

        print("Showing reminder call UI for task: $taskId");

        // Trigger native incoming call screen
        await ReminderCallHelper.showReminderCall(
          taskId: taskId,
          taskTitle: title,
          reminderMessage: reminderText,
        );

        // Optional: also show a local notification as fallback / visual cue
        await _showLocalReminderNotification(title, reminderText, taskId);

        return; // Skip default notification handling for call reminders
      }

      // Normal notification handling (non-call reminders)
      final notification = message.notification;
      if (notification != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true, // Helps show full-screen when tapped
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

    // App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened from background via tap: ${message.data}");
      _handlePayload(message.data);
    });

    // App launched from terminated state via notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _handlePayload(initialMessage.data);
      });
    }
  }

  // Fallback local notification for reminder calls (with full-screen intent)
  Future<void> _showLocalReminderNotification(
    String title,
    String body,
    String taskId,
  ) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 1000000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
          // If you added a custom sound in res/raw/reminder_ring.mp3:
          // sound: const RawResourceAndroidNotificationSound('reminder_ring'),
        ),
      ),
      payload: jsonEncode({'type': 'reminder_call', 'taskId': taskId}),
    );
  }

  static void _handlePayload(Map<String, dynamic> data) {
    print("Handling notification payload: $data");

    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type']?.toString();
    final id = data['id']?.toString();
    final screen = data['screen']?.toString();

    if (type == 'task' && id != null) {
      context.go('/task-details/$id');
    } else if (type == 'note' && id != null) {
      context.go('/note-details/$id');
    } else if (type == 'event' && id != null) {
      context.go('/event-details/$id');
    } else if (screen == 'home') {
      context.go('/home');
    } else if (screen == 'notes') {
      context.go('/notes');
    } else if (screen == 'calendar') {
      context.go('/calendar');
    } else if (type == 'reminder_call') {
      // Optional: go to task details when user taps fallback notification
      final taskId = data['taskId']?.toString();
      if (taskId != null && taskId != 'unknown') {
        context.go('/task-details/$taskId');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/home');
    }
  }
}
