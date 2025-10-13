import 'package:flutter/material.dart';

class RecordingDialogProvider extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;

  bool _callMe = false;
  bool get callMe => _callMe;

  bool _notification = false;
  bool get notification => _notification;

  final TextEditingController titleController =
  TextEditingController(text: "Zen");
  final TextEditingController dateController =
  TextEditingController(text: "Thu, 10 Oct");
  final TextEditingController descController = TextEditingController(
    text:
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  );

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void finishEditing() {
    _isEditing = false;
    notifyListeners();
  }

  void toggleCallMe() {
    _callMe = !_callMe;
    notifyListeners();
  }

  void toggleNotification() {
    _notification = !_notification;
    notifyListeners();
  }
}
