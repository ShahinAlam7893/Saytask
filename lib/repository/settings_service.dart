import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _enableAIChatbot = true;

  bool get enableAIChatbot => _enableAIChatbot;

  void setEnableAIChatbot(bool value) {
    _enableAIChatbot = value;
    notifyListeners();
  }
}