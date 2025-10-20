import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/settings_service.dart';
import 'package:saytask/res/color.dart';
import '../../res/components/recording_completing_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isRecording = false;
  String? _selectedFileName;
  String _transcribedText = "";

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Timer? _mockSpeechTimer; // Simulated speech recognition timer

  @override
  void initState() {
    super.initState();

    // Setup pulsing mic animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _mockSpeechTimer?.cancel();
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

  void _startRecording() {
    setState(() {
      isRecording = true;
      _transcribedText = "";
    });
    _animationController.forward();

    // 🔹 Simulate speech recognition stream
    const fakeSpeechChunks = [
      "Hello there...",
      "I’m testing the SayTask voice feature...",
      "This should show live transcription.",
      "Recording almost done..."
    ];

    int index = 0;
    _mockSpeechTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (index < fakeSpeechChunks.length) {
        setState(() {
          _transcribedText += " ${fakeSpeechChunks[index]}";
        });

        // 🔹 Auto-scroll to the end after updating text
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void _stopRecording() {
    _animationController.stop();
    _mockSpeechTimer?.cancel();
    setState(() {
      isRecording = false;
    });
    _showRecordingCompleteDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();

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
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
        ),
      ),

      // 🔹 Main body
      body: Column(
        children: [
          // 🔹 Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: AppColors.green!, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 14.h,
                ),
              ),
            ),
          ),

          // 🔹 Mic Section & Live Transcription
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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 🔹 Animated Pulsing Mic Circle
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
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 70.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // 🔹 Auto-scrollable live transcription
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: SizedBox(
                        height: 60.h,
                        child: ListView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          children: [
                            Center(
                              child: Text(
                                _transcribedText.isEmpty
                                    ? "Listening..."
                                    : _transcribedText,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
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

      // 🔹 Floating Chat Button
      floatingActionButton: settingsViewModel.enableAIChatbot
          ? SizedBox(
        width: 60.w,
        height: 60.h,
        child: FloatingActionButton(
          onPressed: () {
            context.push('/chat');
          },
          backgroundColor: AppColors.green,
          shape: const CircleBorder(),
          elevation: 4,
          child: Icon(
            Icons.chat,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
      )
          : null,
    );
  }

  void _showRecordingCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordingCompleteDialog(
        onCancel: () => context.pop(context),
        onSave: () {
          context.pop(context);
          // Add save logic here if needed
        },
      ),
    );
  }
}
