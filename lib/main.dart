import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/repository/voice_record_provider_note.dart';
import 'package:saytask/utils/routes/routes.dart';
import 'repository/notes_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => NoteDetailsViewModel()),
        ChangeNotifierProvider(create: (_) => VoiceRecordProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Sytask',
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.tealAccent,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          routerConfig: router,
          builder: (context, widget) {
            // Debug provider availability
            try {
              context.read<NotesProvider>();
              print('NotesProvider found in MyApp');
            } catch (e) {
              print('NotesProvider NOT found in MyApp: $e');
            }
            return widget!;
          },
        );
      },
    );
  }
}