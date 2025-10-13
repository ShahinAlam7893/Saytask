import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../res/color.dart';
import '../../res/components/recording_completing_dialog.dart'; // ✅ Import dialog

class SpeakHomeScreen extends StatefulWidget {
  const SpeakHomeScreen({super.key});

  @override
  State<SpeakHomeScreen> createState() => _SpeakHomeScreenState();
}

class _SpeakHomeScreenState extends State<SpeakHomeScreen> {
  bool isRecording = false;

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
            // Logo
            SvgPicture.asset(
              'assets/images/Saytask_logo.svg',
              height: 24.h,
              width: 100.w,
            ),
            // Settings Icon
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Colors.black,
                size: 24.sp,
              ),
              onPressed: () {
                context.push('/settings');
              },
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
                      onTap: () => setState(() => isRecording = true),
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
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 60.sp,
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
                    // SpeakScreen
                    SpeakScreen(
                      onStop: () {
                        setState(() => isRecording = false);
                        _showRecordingCompleteDialog(context);
                      },
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

  /// ✅ Show Recording Complete Dialog
  void _showRecordingCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordingCompleteDialog(
        onCancel: () {
          Navigator.pop(context); // Close dialog
        },
        onSave: () {
          Navigator.pop(context);
          // You can add your save logic here (e.g., uploading the recording)
        },
      ),
    );
  }
}

class SpeakScreen extends StatelessWidget {
  final VoidCallback onStop;

  const SpeakScreen({super.key, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Red Stop Button
        GestureDetector(
          onTap: onStop,
          child: Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.stop,
              color: Colors.white,
              size: 60.sp,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Recording ...',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.sp,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
