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
  final String type;           // "event", "task", "note"
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

  /// Perfectly matches your real API response
  factory VoiceClassification.fromJson(Map<String, dynamic> json, String rawText) {
    // Your API uses "response_type", not "type"
    final responseType = (json['response_type'] as String?)?.toLowerCase();

    String detectedType = 'note'; // fallback
    if (responseType == 'event' || responseType == 'task') {
      detectedType = responseType ?? 'note';
    }

    // Title: use raw text if API didn't give one
    String title = (json['title'] as String?)?.trim() ??
        rawText.trim().split(' ').take(8).join(' ');
    
    if (title.length > 60) {
      title = title.substring(0, 57) + '...';
    }

    return VoiceClassification(
      type: detectedType,
      title: title.isEmpty ? 'New Item' : title,
      description: json['description'] ?? json['note'],
      date: json['date']?.toString(),
      time: json['time']?.toString(),
      callMe: json['call_me'] == true || json['call'] == true,
      reminder: json['reminder']?.toString() ?? "At time of event",
      rawText: rawText,
    );
  }

  @override
  String toString() {
    return 'VoiceClassification(type: $type, title: $title, date: $date, time: $time)';
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

  Future<void> initialize() async {
    if (_isReady) return;

    int retryCount = 0;
    while (retryCount <= 2 && !_isReady) {
      final success = await _speech.initialize(
        onStatus: (status) => debugPrint('STT status: $status'),
        onError: (error) => debugPrint('STT error: ${error.errorMsg}'),
      );

      if (success) {
        _isReady = true;
        await _setupLocale();
        debugPrint('Speech-to-Text initialized');
        break;
      }
      retryCount++;
      await Future.delayed(const Duration(seconds: 1));
    }
    notifyListeners();
  }

  Future<void> _setupLocale() async {
    try {
      final locales = await _speech.locales();
      _localeId = locales.firstWhere(
        (l) => l.localeId.startsWith('en'),
        orElse: () => locales.first,
      ).localeId;
    } catch (e) {
      _localeId = 'en_US';
    }
  }

  Future<bool> startListening() async {
    if (!_isReady) await initialize();
    if (!_isReady) return false;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _errorMessage = 'Microphone permission required';
      notifyListeners();
      return false;
    }

    if (_isListening) return true;

    _text = '';
    _isListening = true;
    _shouldShowCard = false;
    _lastClassification = null;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _text = result.recognizedWords;
        _confidence = result.hasConfidenceRating ? result.confidence : 0.0;
        notifyListeners();
      },
      localeId: _localeId,
      partialResults: true,
      listenMode: ListenMode.confirmation,
    );

    return true;
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    debugPrint('Speech stopped. Text: "$_text"');

    if (_text.trim().isEmpty) {
      notifyListeners();
      return;
    }

    await _classifyAndTriggerCard(_text.trim());
  }

  Future<void> _classifyAndTriggerCard(String message) async {
    _isClassifying = true;
    notifyListeners();

    try {
      await LocalStorageService.init();
      final token = LocalStorageService.token;
      if (token == null) throw Exception("Not authenticated");

      final response = await http.post(
        Uri.parse('${Urls.baseUrl}/chatbot/classify/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({"message": message}), // CORRECT: use 'message' parameter
      );

      debugPrint('Raw AI response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _lastClassification = VoiceClassification.fromJson(data, message);
        _shouldShowCard = true;

        debugPrint('SUCCESS → Type: ${_lastClassification!.type.toUpperCase()}');
        debugPrint('Title: ${_lastClassification!.title}');
        debugPrint('Date: ${_lastClassification!.date}');
        debugPrint('Time: ${_lastClassification!.time}');
      } else {
        throw Exception("Server error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('AI classification failed: $e → using fallback');
      // Fallback: treat as note
      _lastClassification = VoiceClassification(
        type: 'note',
        title: message.length > 40 ? message.substring(0, 37) + '...' : message,
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

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}