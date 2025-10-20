// lib/widgets/voice_recorder_widget.dart
import 'package:flutter/material.dart';
import 'package:saytask/res/color.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String)? onTextChange;
  final Function()? onStart;
  final Function(String)? onStop;

  const VoiceRecorderWidget({
    super.key,
    this.onTextChange,
    this.onStart,
    this.onStop,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late stt.SpeechToText _speech;
  String _recognizedText = "";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isRecording = true);
      widget.onStart?.call();

      _speech.listen(onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        widget.onTextChange?.call(_recognizedText);
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isRecording = false);
    widget.onStop?.call(_recognizedText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isRecording ? _stopListening : _startListening,
          child: ScaleTransition(
            scale: _isRecording ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 60.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 30.h),
        Text(
          _isRecording
              ? (_recognizedText.isEmpty ? "Listening..." : _recognizedText)
              : "Tap to saytask",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.black87,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
