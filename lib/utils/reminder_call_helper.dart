// lib/utils/reminder_call_helper.dart
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'dart:math';

class ReminderCallHelper {
  static Future<void> showReminderCall({
    required String taskId,
    required String taskTitle,
    required String itemId,
    String? reminderMessage = "It's time to complete your task",
    int autoDeclineAfterSeconds = 60,
    Map<String, dynamic>? extra,
  }) async {
    final String callUuid = Random().nextInt(999999).toString();

    final params = CallKitParams(
      id: callUuid,                           
      nameCaller: 'SayTask Reminder',
      appName: 'SayTask',
      handle: reminderMessage ?? taskTitle,  
      type: 0,                                
      duration: autoDeclineAfterSeconds * 1000, 
      textAccept: 'Start',
      textDecline: 'Snooze',
      android: const AndroidParams(
        isCustomNotification: true,
        ringtonePath: 'system_ringtone_default', 
        actionColor: '#22C55E',                 
        incomingCallNotificationChannelName: "SayTask Reminders",
      ),
      ios: const IOSParams(
        ringtonePath: 'system_ringtone_default',
        handleType: 'generic',
      ),
      extra: {
        'taskId': taskId,
        'type': 'reminder',
        'itemId': itemId,
        ...?extra,
      },
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      print("Reminder call UI shown for task: $taskId");
      print("Reminder call UI shown for item: $itemId");
    } catch (e) {
      print("Failed to show callkit: $e");
    }
  }

  static Future<void> endCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }
}