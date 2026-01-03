import 'package:flutter/material.dart';

class VoiceRecordProvider with ChangeNotifier {
  bool _isRecording = false;
  String _noteContent = '';
  String _summary = '';

  bool get isRecording => _isRecording;
  String get noteContent => _noteContent;
  String get summary => _summary;

  void startRecording() {
    _isRecording = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      _isRecording = false;
      _noteContent =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit...";
      _summary = '''
• Try blue and orange for dashboard color
• Talk with dev team about login page bug
• Change the heading font
''';
      notifyListeners();
    });
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }

  void resetRecording() {
    _isRecording = false;
    _noteContent = '';
    _summary = '';
    notifyListeners();
  }
}
