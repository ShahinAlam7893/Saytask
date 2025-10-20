import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../res/color.dart';
import '../../res/components/recording_completing_dialog.dart';

class SpeakHomeScreen extends StatefulWidget {
  const SpeakHomeScreen({super.key});

  @override
  State<SpeakHomeScreen> createState() => _SpeakHomeScreenState();
}

class _SpeakHomeScreenState extends State<SpeakHomeScreen>
    with SingleTickerProviderStateMixin {
  bool isRecording = false;
  String _transcribedText = "";
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      _transcribedText = "";
    });
    _simulateTranscription();
  }

  void _stopRecording() {
    setState(() {
      isRecording = false;
    });
    _showRecordingCompleteDialog(context);
  }

  /// ✅ Simulated live transcription (auto-scroll)
  void _simulateTranscription() async {
    final simulatedWords = [
      "Meeting",
      "today",
      "at",
      "10",
      "AM",
      "with",
      "Zen...",
      "Don't",
      "forget",
      "to",
      "bring",
      "the",
      "presentation.",
    ];

    for (var word in simulatedWords) {
      if (!isRecording) break;
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _transcribedText += "$word ";
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// ✅ Recording completion dialog
  void _showRecordingCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordingCompleteDialog(
        onCancel: () => Navigator.pop(context),
        onSave: () {
          Navigator.pop(context);
          // Add save logic here (e.g. upload audio or store transcription)
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              icon: Icon(Icons.settings_outlined,
                  color: Colors.black, size: 24.sp),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRecording) ...[
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 160.w,
                        height: 160.w,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(Icons.mic, color: Colors.white, size: 60.sp),
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
                        children: const [
                          TextSpan(text: 'Tap to '),
                          TextSpan(
                            text: 'saytask',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      'Meeting today at 10 AM with Zen....',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    // 🎤 Animated Mic
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        onTap: _stopRecording,
                        child: Container(
                          width: 180.w,
                          height: 180.w,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child:
                          Icon(Icons.mic, color: Colors.white, size: 70.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // 🔹 Auto-scrollable transcription
                    Container(
                      height: 60.h,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Center(
                          child: Text(
                            _transcribedText.isEmpty
                                ? "Listening..."
                                : _transcribedText,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
