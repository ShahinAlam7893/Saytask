import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// ====================================================
/// OPTIMIZED, REUSABLE Speech-to-Text Provider
/// Works everywhere: Note, Task, Event, Bottom Nav, etc.
/// ====================================================
class SpeechProvider with ChangeNotifier {
  // Singleton (optional – use if you want ONE instance app-wide)
  static final SpeechProvider _instance = SpeechProvider._internal();
  factory SpeechProvider() => _instance;
  SpeechProvider._internal();

  final SpeechToText _speech = SpeechToText();

  // State
  bool _isReady = false;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0.0;
  String _localeId = 'en_US';
  String _errorMessage = '';

  // Public Getters
  bool get isReady => _isReady;
  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;
  String get error => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Configurable
  static const Duration listenDuration = Duration(seconds: 30);
  static const Duration pauseDuration = Duration(seconds: 5);

  // ---------------------------------------------------------
  // 1. Initialize + Auto-retry on failure
  // ---------------------------------------------------------
  Future<void> initialize() async {
    if (_isReady) return;

    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries && !_isReady) {
      final success = await _speech.initialize(
        onStatus: (status) => debugPrint('STT status: $status'),
        onError: (error) {
          final msg = 'SpeechRecognitionError msg: ${error.errorMsg}, permanent: ${error.permanent}';
          debugPrint('STT init error: $msg');
          _errorMessage = error.errorMsg;
          notifyListeners();
        },
      );

      if (success) {
        _isReady = true;
        await _setupLocale();
        _errorMessage = '';
        debugPrint('Speech engine initialized successfully');
      } else {
        retryCount++;
        if (retryCount <= maxRetries) {
          debugPrint('Retrying speech init... ($retryCount/$maxRetries)');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    notifyListeners();
  }

  Future<void> _setupLocale() async {
    try {
      final locales = await _speech.locales();
      final preferred = locales.firstWhere(
            (l) => l.localeId.startsWith('en'),
        orElse: () => locales.first,
      );
      _localeId = preferred.localeId;
      debugPrint('Using locale: $_localeId - ${preferred.name}');
    } catch (e) {
      debugPrint('Locale setup failed: $e');
    }
  }

  // ---------------------------------------------------------
  // 2. Start Listening (Smart + Safe)
  // ---------------------------------------------------------
  Future<bool> startListening() async {
    // Ensure initialized
    if (!_isReady) await initialize();
    if (!_isReady) {
      _errorMessage = 'Speech engine not available';
      notifyListeners();
      return false;
    }

    // Request mic
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _errorMessage = 'Microphone permission denied';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }

    if (_isListening) return true;

    // Reset
    _text = '';
    _confidence = 0.0;
    _errorMessage = '';
    _isListening = true;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _text = result.recognizedWords;
          _confidence = result.hasConfidenceRating ? result.confidence : 0.0;

          debugPrint(
              'LIVE: "$_text" | Confidence: ${(_confidence * 100).toStringAsFixed(1)}%');

          notifyListeners();
        },
        localeId: _localeId,
        listenFor: listenDuration,
        pauseFor: pauseDuration,
        partialResults: true,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Listen failed: $e');
      _errorMessage = 'Failed to start listening';
      _isListening = false;
      notifyListeners();
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------
  // 3. Stop Listening
  // ---------------------------------------------------------
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;

    debugPrint(
        'SPEECH STOPPED – Final: "$_text" | Confidence: ${(_confidence * 100).toStringAsFixed(1)}%');

    notifyListeners();
  }

  // ---------------------------------------------------------
  // 4. Clear Results
  // ---------------------------------------------------------
  void clear() {
    _text = '';
    _confidence = 0.0;
    _errorMessage = '';
    notifyListeners();
  }

  // ---------------------------------------------------------
  // 5. Cancel (if needed)
  // ---------------------------------------------------------
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
    clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}