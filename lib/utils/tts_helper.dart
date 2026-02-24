import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  static Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  // Example usage for reminder
  static Future<void> speakReminder(String taskTitle) async {
    final message = "Reminder: $taskTitle. It's time to get it done!";
    await speak(message);
  }
}