// lib/repository/speech_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/service/local_storage_service.dart';

class VoiceClassification {
  final String type;
  final String title;
  final String? description;
  final String? date; 
  final String? time;
  final bool callMe;
  final String reminder;  
  final String rawText;

  VoiceClassification({
    required this.type,
    required this.title,
    this.description,
    this.date,
    this.time,
    this.callMe = false,
    this.reminder = "At time of event",
    required this.rawText,
  });

  factory VoiceClassification.fromJson(Map<String, dynamic> json, String rawText) {
    return VoiceClassification(
      type: json['type']?.toString().toLowerCase() ?? 'note',
      title: json['title'] ?? 'New Item',
      description: json['description'] ?? json['note'],
      date: json['date'],
      time: json['time'],
      callMe: json['call_me'] == true,
      reminder: json['reminder'] ?? "At time of event",
      rawText: rawText,
    );
  }
}

class SpeechProvider with ChangeNotifier {
  static final SpeechProvider _instance = SpeechProvider._internal();
  factory SpeechProvider() => _instance;
  SpeechProvider._internal();

  final SpeechToText _speech = SpeechToText();

  // Speech state
  bool _isReady = false;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0.0;
  String _localeId = 'en_US';
  String _errorMessage = '';

  // Classification state
  VoiceClassification? _lastClassification;
  bool _shouldShowCard = false;
  bool _isClassifying = false;

  // Getters
  bool get isReady => _isReady;
  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;
  String get error => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  VoiceClassification? get lastClassification => _lastClassification;
  bool get shouldShowCard => _shouldShowCard;
  bool get isClassifying => _isClassifying;

  static const Duration listenDuration = Duration(seconds: 30);
  static const Duration pauseDuration = Duration(seconds: 5);

  Future<void> initialize() async {
    if (_isReady) return;

    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries && !_isReady) {
      final success = await _speech.initialize(
        onStatus: (status) => debugPrint('STT status: $status'),
        onError: (error) {
          debugPrint('STT init error: ${error.errorMsg}');
          _errorMessage = error.errorMsg;
          notifyListeners();
        },
      );

      if (success) {
        _isReady = true;
        await _setupLocale();
        _errorMessage = '';
        debugPrint('Speech engine initialized');
      } else {
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
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
    } catch (e) {
      debugPrint('Locale setup failed: $e');
    }
  }

  Future<bool> startListening() async {
    if (!_isReady) await initialize();
    if (!_isReady) {
      _errorMessage = 'Speech engine not available';
      notifyListeners();
      return false;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _errorMessage = 'Microphone permission denied';
      notifyListeners();
      return false;
    }

    if (_isListening) return true;

    _text = '';
    _confidence = 0.0;
    _errorMessage = '';
    _isListening = true;
    _shouldShowCard = false;
    _lastClassification = null;

    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _text = result.recognizedWords;
          _confidence = result.hasConfidenceRating ? result.confidence : 0.0;
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
      _errorMessage = 'Failed to start listening';
      _isListening = false;
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Called when user taps mic to stop
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    debugPrint('Speech stopped. Final text: "$_text"');

    if (_text.trim().isEmpty) {
      notifyListeners();
      return;
    }

    await _classifyAndTriggerCard(_text.trim());
  }

  Future<void> _classifyAndTriggerCard(String message) async {
    _isClassifying = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await LocalStorageService.init();
      final token = LocalStorageService.token;
      if (token == null) throw Exception("Not logged in");

      final response = await http.post(
        Uri.parse('${Urls.baseUrl}/chatbot/classify/'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({"message": text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _lastClassification = VoiceClassification.fromJson(data, message);
        _shouldShowCard = true;
        debugPrint('AI Classification: ${_lastClassification!.type.toUpperCase()} ');
        debugPrint('AI Classification Date: ${_lastClassification!.date?.toUpperCase()} ');
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Classification failed: $e');

      _lastClassification = VoiceClassification(
        type: 'note',
        title: 'Voice Note',
        rawText: message,
      );
      _shouldShowCard = true;
    } finally {
      _isClassifying = false;
      notifyListeners();
    }
  }


  void resetCardState() {
    _shouldShowCard = false;
    _lastClassification = null;
    _text = '';
    notifyListeners();
  }

  void clear() {
    _text = '';
    _confidence = 0.0;
    _errorMessage = '';
    notifyListeners();
  }

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