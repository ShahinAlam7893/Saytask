// lib/repository/speech_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/repository/voice_action_repository.dart';
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
  final List<String>? tags;
  final String? location;
  final bool isAllDay;

  VoiceClassification({
    required this.type,
    required this.title,
    this.description,
    this.date,
    this.time,
    this.callMe = false,
    this.reminder = "At time of event",
    required this.rawText,
    this.tags = const [],
    this.location,
    this.isAllDay = false,
  });

  factory VoiceClassification.fromJson(Map<String, dynamic> json, String rawText) {
    final responseType = (json['response_type'] as String?)?.toLowerCase() ?? 'note';
    final detectedType = ['event', 'task'].contains(responseType) ? responseType : 'note';

    String title = (json['title'] as String?)?.trim() ?? rawText.trim().split(' ').take(8).join(' ');
    if (title.length > 60) title = '${title.substring(0, 57)}...';

    // Parse date/time with proper fallback to current date
    String? date;
    String? time;
    bool isAllDay = false;
    DateTime? parsedUtc;

    if (detectedType == 'event') {
      final dtStr = json['event_datetime'] as String?;
      parsedUtc = dtStr != null ? DateTime.tryParse(dtStr) : null;
    } else if (detectedType == 'task') {
      final dtStr = json['start_time'] as String?;
      parsedUtc = dtStr != null ? DateTime.tryParse(dtStr) : null;
    }

    if (parsedUtc != null) {
      final local = parsedUtc.toLocal();
      date = DateFormat('yyyy-MM-dd').format(local);
      if (local.hour == 0 && local.minute == 0) {
        isAllDay = true;
        time = null;
      } else {
        time = DateFormat('HH:mm').format(local);
      }
    } else {
      // CRITICAL FIX: Default to current date/time if null
      final now = DateTime.now();
      date = DateFormat('yyyy-MM-dd').format(now);
      time = DateFormat('HH:mm').format(now.add(const Duration(hours: 1))); 
    }

    // Fallback for old format
    time ??= json['time']?.toString();

    String description = (json['description'] as String?)?.trim() ?? '';
    if (description.isEmpty) description = rawText;

    // Reminder parsing
    String reminderText = "At time of event";
    final reminders = json['reminders'] as List<dynamic>? ?? [];
    if (reminders.isNotEmpty) {
      final minutes = (reminders.first as Map)['time_before'] as int? ?? 0;
      reminderText = minutes == 0
          ? "At time of event"
          : {
        5: "5 minutes before",
        10: "10 minutes before",
        15: "15 minutes before",
        30: "30 minutes before",
        60: "1 hour before",
        120: "2 hours before",
      }[minutes] ?? "$minutes minutes before";
    }

    bool hasCall = reminders.any((r) => (r['types'] as List<dynamic>?)?.contains('call') == true);

    return VoiceClassification(
      type: detectedType,
      title: title.isEmpty ? 'New Item' : title,
      description: description,
      date: date,
      time: time,
      isAllDay: isAllDay,
      callMe: hasCall || json['call_me'] == true || json['call'] == true,
      reminder: reminderText,
      rawText: rawText,
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location'] ?? json['location_address'],
    );
  }

  @override
  String toString() => 'VoiceClassification(type: $type, title: $title, date: $date, time: $time)';
}

class SpeechProvider with ChangeNotifier {
  static final SpeechProvider _instance = SpeechProvider._internal();
  factory SpeechProvider() => _instance;
  SpeechProvider._internal();

  final SpeechToText _speech = SpeechToText();

  bool _isReady = false;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0.0;
  String _localeId = 'en_US';
  String _errorMessage = '';

  VoiceClassification? _lastClassification;
  bool _shouldShowCard = false;
  bool _isClassifying = false;

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
      _localeId = locales
          .firstWhere(
            (l) => l.localeId.startsWith('en'),
        orElse: () => locales.first,
      )
          .localeId;
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
        body: json.encode({"message": message}),
      );

      debugPrint('Classification response: ${response.body}');

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
      debugPrint('Classification failed: $e → using fallback');
      _lastClassification = VoiceClassification(
        type: 'note',
        title: message.length > 40 ? '${message.substring(0, 37)}...' : message,
        rawText: message,
      );
      _shouldShowCard = true;
    } finally {
      _isClassifying = false;
      notifyListeners();
    }
  }

  Future<void> saveCurrentClassification(BuildContext context) async {
    if (_lastClassification == null) return;

    _isClassifying = true;
    notifyListeners();

    try {
      final repo = VoiceActionRepository();
      await repo.saveVoiceAction(_lastClassification!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_lastClassification!.type[0].toUpperCase()}${_lastClassification!.type.substring(1)} saved successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      final type = _lastClassification!.type;

      if (type == 'event') {
        context.read<CalendarProvider>().loadEvents();
      } else if (type == 'task') {
        context.read<TaskProvider>().loadTasks();
      } else if (type == 'note') {
        context.read<NotesProvider>().loadNotes();
      }

      resetCardState();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
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