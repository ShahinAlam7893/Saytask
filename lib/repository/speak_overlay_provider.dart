import 'package:flutter/material.dart';

class SpeakOverlayProvider extends ChangeNotifier {
  bool _isOverlayVisible = false;

  bool get isOverlayVisible => _isOverlayVisible;

  void showOverlay() {
    _isOverlayVisible = true;
    notifyListeners();
  }

  void hideOverlay() {
    _isOverlayVisible = false;
    notifyListeners();
  }

  void toggleOverlay() {
    _isOverlayVisible = !_isOverlayVisible;
    notifyListeners();
  }
}