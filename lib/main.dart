// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:saytask/repository/notification_service.dart';
import 'package:saytask/utils/reminder_call_helper.dart';

import 'firebase_options.dart';
import 'repository/calendar_service.dart';
import 'repository/chat_service.dart';
import 'repository/settings_service.dart';
import 'repository/speak_overlay_provider.dart';
import 'repository/speech_provider.dart';
import 'repository/today_task_service.dart';
import 'repository/voice_record_provider_note.dart';
import 'repository/notes_service.dart';
import 'repository/plan_service.dart';
import 'view_model/auth_view_model.dart';
import 'utils/routes/routes.dart';
import 'service/local_storage_service.dart';

// ──────────────────────────────────────────────────────────────
// TTS global helpers
final FlutterTts _tts = FlutterTts();

Future<void> initTts() async {
  try {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    print("TTS initialized");
  } catch (e) {
    print("TTS init failed: $e");
  }
}

Future<void> speakReminder(String message) async {
  try {
    await _tts.speak(message);
    print("TTS played: \"$message\"");
  } catch (e) {
    print("TTS speak error: $e");
  }
}

// ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalStorageService.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService().initialize();
  await initTts();

  _initCallkitListener();

  runApp(const MyApp());
}

// Root widget that safely initializes everything
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => NoteDetailsViewModel()),
        ChangeNotifierProvider(create: (_) => VoiceRecordProvider()),
        ChangeNotifierProvider(create: (_) => PlanViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => SpeakOverlayProvider()),
        ChangeNotifierProvider(create: (_) => SpeechProvider()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: const _DeferredInitializer(),
    );
  }
}

class _DeferredInitializer extends StatefulWidget {
  const _DeferredInitializer();

  @override
  State<_DeferredInitializer> createState() => _DeferredInitializerState();
}

class _DeferredInitializerState extends State<_DeferredInitializer> {
  @override
  void initState() {
    super.initState();
    // Now context.read() is safe — providers are above us
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().loadUserFromStoredToken();
      print("Auth loading triggered after providers are ready");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'SayTask',
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.tealAccent,
            textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}

void _initCallkitListener() {
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
    if (event == null) return;

    print("CallKit Event → ${event.event} | Body: ${event.body}");

    final String? callId = event.body?['id'] as String?;
    final Map<dynamic, dynamic>? extra = event.body?['extra'] as Map?;
    final String? taskId = extra?['taskId'] as String?;
    final String? reminderMessage = extra?['reminderMessage'] as String?;

    switch (event.event) {
      case Event.actionCallAccept:
        if (taskId != null) {
          print("Reminder ACCEPTED → Task/Event ID: $taskId");

          final speakText = reminderMessage ??
              "Reminder for task $taskId. Time to complete it now!";
          await speakReminder(speakText);

          Future.delayed(const Duration(seconds: 10), () async {
            if (callId != null) {
              await FlutterCallkitIncoming.endCall(callId);
            }
          });
        }
        break;

      case Event.actionCallDecline:
        print("Reminder DECLINED / SNOOZED → Task ID: $taskId");
        if (callId != null) {
          await FlutterCallkitIncoming.endCall(callId);
        }
        if (taskId != null) {
          print("→ Snoozing task $taskId (implement later)");
        }
        break;

      case Event.actionCallIncoming:
        print("Incoming reminder call UI displayed");
        break;

      case Event.actionCallStart:
      case Event.actionCallConnected:
        print("Reminder call started/connected");
        break;

      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        print("Reminder call ended or timed out");
        break;

      case Event.actionDidUpdateDevicePushTokenVoip:
        final token = event.body?['token'] as String?;
        print("VoIP Token: $token");
        break;

      default:
        print("Unhandled CallKit event: ${event.event}");
    }
  });
}