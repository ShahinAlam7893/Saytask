import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/speak_overlay_provider.dart';
// Import your AppColors and RecordingCompleteDialog
// import 'package:saytask/res/color.dart';
// import 'package:saytask/res/components/recording_completing_dialog.dart';

/// The actual content of the speak overlay (replicates SpeakHomeScreen UI)
class SpeakOverlayContent extends StatefulWidget {
  const SpeakOverlayContent({super.key});

  @override
  State<SpeakOverlayContent> createState() => _SpeakOverlayContentState();
}

class _SpeakOverlayContentState extends State<SpeakOverlayContent>
    with SingleTickerProviderStateMixin {
  bool isRecording = false;
  String _transcribedText = "";
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showRecordingCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Complete'),
        content: const Text('Your recording has been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add save logic here
            },
            child: const Text('Save'),
          ),
        ],
      ),
      // Uncomment below to use your custom dialog:
      // builder: (context) => RecordingCompleteDialog(
      //   onCancel: () => Navigator.pop(context),
      //   onSave: () {
      //     Navigator.pop(context);
      //   },
      // ),
    );
  }

  void _closeOverlay() {
    final overlayProvider = context.read<SpeakOverlayProvider>();
    overlayProvider.hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    // Use your AppColors.green here instead of Colors.green
    final greenColor = Colors.green; // Replace with AppColors.green

    return Column(
      children: [
        // Close button at the top
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: IconButton(
                icon: Icon(Icons.close, size: 28.sp),
                onPressed: _closeOverlay,
              ),
            ),
          ),
        ),

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
                        color: greenColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: greenColor.withOpacity(0.3),
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
                      color: greenColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  // Animated Mic
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 180.w,
                        height: 180.w,
                        decoration: BoxDecoration(
                          color: greenColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: greenColor.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.mic, color: Colors.white, size: 70.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // Auto-scrollable transcription
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
    );
  }
}