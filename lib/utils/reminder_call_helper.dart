import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'dart:math';

class ReminderCallHelper {
  static Future<void> showReminderCall({
    required String taskId,
    required String taskTitle,
    String? reminderMessage = "It's time to complete your task",
    int autoDeclineAfterSeconds = 45,
  }) async {
    final String callUuid = Random().nextInt(999999).toString(); // or use uuid package

    final params = CallKitParams(
      id: callUuid,                             // unique per call
      nameCaller: 'SayTask Reminder',
      appName: 'SayTask',
      handle: reminderMessage ?? taskTitle,    // shows as subtitle / number field
      type: 0,                                  // 0 = voice/audio
      duration: autoDeclineAfterSeconds * 1000, // ms
      textAccept: 'Start',
      textDecline: 'Snooze',
      android: const AndroidParams(
        isCustomNotification: true,
        ringtonePath: 'system_ringtone_default', // or 'raw/reminder_ring'
        actionColor: '#22C55E',                  // your green color
        incomingCallNotificationChannelName: "SayTask Reminders",
      ),
      extra: {'taskId': taskId, 'type': 'reminder'},
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      print("Reminder call UI shown for task: $taskId");
    } catch (e) {
      print("Failed to show callkit: $e");
    }
  }

  static Future<void> endCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }
}