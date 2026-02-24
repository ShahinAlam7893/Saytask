// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/utils/reminder_call_helper.dart';
import 'package:saytask/utils/tts_helper.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import '../utils/routes/routes.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background FCM Message: ${message.messageId} | Data: ${message.data}");
  await NotificationService._instance._handleMessage(message);
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

  StreamSubscription? _callKitSubscription;

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
        final payloadStr = response.payload;
        if (payloadStr != null) {
          try {
            final data = jsonDecode(payloadStr) as Map<String, dynamic>;
            _handlePayload(data);
          } catch (e) {
            print("Error parsing payload: $e");
          }
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Initialize TTS
    await TtsHelper.init();

    // Setup FCM listeners
    FirebaseMessaging.onMessage.listen(_handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message);
    });

    // Setup CallKit event listeners
    _setupCallKitListeners();
  }

  void _setupCallKitListeners() {
    _callKitSubscription = FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      final body = event.body as Map<String, dynamic>? ?? {};
      final extra = body['extra'] as Map<String, dynamic>? ?? {};
      final type = extra['type'] as String?;
      final taskId = extra['taskId'] as String?;
      final itemId = extra['itemId'] as String?;
      final reminderMessage =
          body['handle'] as String? ?? "It's time for your reminder";
      final reminderType =
          extra['reminder_type'] as String? ??
          'task'; // 'task', 'event', or 'chat'

      switch (event.event) {
        case 'com.hutvecklare.appcallkit.ACTION_CALL_ACCEPT':
          print("Reminder call accepted for $type: $taskId / $itemId");
          // Speak the reminder message
          await TtsHelper.speak(reminderMessage);
          // Navigate to details if app is open
          final context = router.routerDelegate.navigatorKey.currentContext;
          if (context != null) {
            if (reminderType == 'task' && taskId != null) {
              context.go('/task-details/$taskId');
            } else if (reminderType == 'event' && itemId != null) {
              context.go(
                '/event-details/$itemId',
              ); // Assuming event details path uses itemId
            } else if (reminderType == 'chat' && itemId != null) {
              context.go('/chat'); // Or specific chat message if possible
            }
          }
          // End the call UI after accept
          await FlutterCallkitIncoming.endCall(body['id'] as String);
          break;

        case 'com.hutvecklare.appcallkit.ACTION_CALL_DECLINE':
          print("Reminder call declined for $type: $taskId / $itemId");
          // Optionally snooze or reschedule via backend
          await FlutterCallkitIncoming.endCall(body['id'] as String);
          break;

        case 'com.hsviluppare.appcallkit.ACTION_CALL_TIMEOUT':
          print("Reminder call timed out for $type: $taskId / $itemId");
          // Handle timeout if needed
          break;

        default:
          break;
      }
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final data = message.data;
    print("Handling FCM message: ${data}");

    if (data['type'] == 'reminder_call') {
      final taskId = data['task_id'] as String? ?? Uuid().v4();
      final itemId = data['item_id'] as String? ?? Uuid().v4();
      final taskTitle = data['title'] as String? ?? 'Reminder';
      final reminderMessage =
          data['message'] as String? ?? "It's time for your task";
      final reminderType =
          data['reminder_type'] as String? ??
          'task'; // 'task', 'event', or 'chat'

      await ReminderCallHelper.showReminderCall(
        taskId: taskId,
        taskTitle: taskTitle,
        itemId: itemId,
        reminderMessage: reminderMessage,
        extra: {'reminder_type': reminderType}, // Pass extra for type
      );
    } else {
      // Show regular notification
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
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: jsonEncode(data),
        );
      }
    }
  }

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
    final reminderType = data['reminder_type']?.toString();

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
      final itemId = data['itemId']?.toString();
      if (reminderType == 'task' && taskId != null) {
        context.go('/task-details/$taskId');
      } else if (reminderType == 'event' && itemId != null) {
        context.go('/event-details/$itemId');
      } else if (reminderType == 'chat') {
        context.go('/chat'); // Navigate to chat screen
      } else {
        context.go('/home');
      }
    } else {
      context.go('/home');
    }
  }

  Future<void> dispose() async {
    _callKitSubscription?.cancel();
  }
}
