import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/settings_service.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/speak_screen/event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // UI (unchanged)
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isRecording = false;
  String? _selectedFileName = "";

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  Timer? _typingTimer;
  String? _displayedHint = "";
  int _hintIndex = 0;

  final List<String> _preRecordingHints = [
    "Meeting today at 10 AM with Zen...",
    "Set a medication reminder for 8 PM...",
    "Plan weekend trip to the mountains...",
    "Buy groceries on the way home...",
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startHintTypingAnimation();
  }

  void _startHintTypingAnimation() {
    _typingTimer?.cancel();
    _displayedHint = "";
    int charIndex = 0;
    String fullHint = _preRecordingHints[_hintIndex];

    _typingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;

      if (charIndex < fullHint.length) {
        setState(() {
          _displayedHint = fullHint.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _hintIndex = (_hintIndex + 1) % _preRecordingHints.length;
          });
          _startHintTypingAnimation();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.single.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File selected: ${result.files.single.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file selected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  // MIC TAP → USE PROVIDER
  // ──────────────────────────────────────────────────────────────
  Future<void> _onMicTap() async {
    final speech = context.read<SpeechProvider>();

    if (isRecording) {
      await speech.stopListening();
      _showRecordingCompleteDialog(context);
    } else {
      final started = await speech.startListening();
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot start speech recognition')),
        );
      }
    }

    setState(() => isRecording = !isRecording);
  }

  // ──────────────────────────────────────────────────────────────
  // UI (100% unchanged – only reads from provider)
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final speech = context.watch<SpeechProvider>(); // ← LISTEN TO PROVIDER

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70.h,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/images/Saytask_logo.svg',
              height: 24.h,
              width: 100.w,
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Colors.black,
                size: 24.sp,
              ),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.only(
              top: 50.h,
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Write or attach your pen...",
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    onPressed: _pickFile,
                    icon: Icon(
                      Icons.attach_file,
                      color: Colors.grey[600],
                      size: 20.sp,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: BorderSide(
                      color: AppColors.green!,
                      width: 0.8.w,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: BorderSide(
                      color: AppColors.green!,
                      width: 0.8.w,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: BorderSide(
                      color: AppColors.green!,
                      width: 0.8.w,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                ),
              ),
            ),
          ),

          // Mic Section
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: _onMicTap,
                      child: Container(
                        width: 160.w,
                        height: 160.w,
                        decoration: BoxDecoration(
                          color: isRecording ? Colors.red : AppColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isRecording ? Colors.red : AppColors.green)
                                      .withOpacity(0.4),
                              blurRadius: 25.r,
                              spreadRadius: 5.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 60.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: 'Tap to '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: SvgPicture.asset(
                            'assets/images/Saytask_logo_without_icon.svg',
                            height: 18.h,
                            width: 18.w,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live Text / Hint
                  SizedBox(
                    height: 60.h,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isRecording
                          ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: ListView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  Center(
                                    child: Text(
                                      speech.text.isEmpty
                                          ? "Listening..."
                                          : speech.text,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: AppColors.black,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Text(
                                _displayedHint ?? "",
                                key: ValueKey(_displayedHint),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: AppColors.green,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: settingsViewModel.enableAIChatbot
          ? SizedBox(
              width: 60.w,
              height: 60.h,
              child: FloatingActionButton(
                onPressed: () => context.push('/chat'),
                backgroundColor: AppColors.green,
                shape: const CircleBorder(),
                elevation: 4,
                child: Icon(Icons.chat, color: Colors.white, size: 28.sp),
              ),
            )
          : null,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // DIALOG – uses provider text
  // ──────────────────────────────────────────────────────────────
  void _showRecordingCompleteDialog(BuildContext context) {
    final speech = context.read<SpeechProvider>();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SpeackEventCard(
                  eventTitle: "Voice Summary",
                  note: speech.text.trim().isEmpty
                      ? "No speech detected"
                      : speech.text.trim(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
