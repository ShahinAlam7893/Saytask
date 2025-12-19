// lib/view/home/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/repository/settings_service.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/repository/voice_action_repository.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/service/local_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isRecording = false;
  String? _selectedFileName;
  File? _selectedFile;
  bool _isProcessing = false;

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

  // ⭐ PICK FILE
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFile = file;
      });

      TopSnackBar.show(
        context,
        message: 'File selected: ${result.files.single.name}',
        backgroundColor: Colors.green[700]!,
      );

      // Auto-process file
      await _processFile();
    }
  }

  // ⭐ PROCESS TEXT INPUT
  Future<void> _processTextInput() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      TopSnackBar.show(
        context,
        message: 'Please enter some text',
        backgroundColor: Colors.orange[700]!,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await LocalStorageService.init();
      final token = LocalStorageService.token;
      if (token == null) throw Exception("Not authenticated");

      // Classify text using chatbot/classify endpoint
      final response = await http.post(
        Uri.parse('${Urls.baseUrl}chatbot/classify/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({"message": text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await _saveClassifiedData(data, text);

        _searchController.clear();
        setState(() => _selectedFileName = null);

        if (!mounted) return;
        TopSnackBar.show(
          context,
          message: 'Successfully created from text!',
          backgroundColor: Colors.green[700]!,
        );
      } else {
        throw Exception("Classification failed");
      }
    } catch (e) {
      if (!mounted) return;
      TopSnackBar.show(
        context,
        message: 'Failed to process: $e',
        backgroundColor: Colors.red[700]!,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ⭐ PROCESS FILE
  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() => _isProcessing = true);

    try {
      await LocalStorageService.init();
      final token = LocalStorageService.token;
      if (token == null) throw Exception("Not authenticated");

      // Summarize document
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Urls.baseUrl}/chatbot/summarize-document/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );
      request.fields['custom_prompt'] =
          'Extract tasks, events, and notes from this document';
      request.fields['max_length'] = '500';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = data['summary'] as String;

        // Classify summary
        final classifyResponse = await http.post(
          Uri.parse('${Urls.baseUrl}/chatbot/classify/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({"message": summary}),
        );

        if (classifyResponse.statusCode == 200) {
          final classifiedData =
              json.decode(classifyResponse.body) as Map<String, dynamic>;
          await _saveClassifiedData(classifiedData, summary);

          setState(() {
            _selectedFileName = null;
            _selectedFile = null;
          });

          if (!mounted) return;
          TopSnackBar.show(
            context,
            message: 'Successfully created from file!',
            backgroundColor: Colors.green[700]!,
          );
        }
      } else {
        throw Exception("File processing failed");
      }
    } catch (e) {
      if (!mounted) return;
      TopSnackBar.show(
        context,
        message: 'Failed to process file',
        // message: 'Failed to process file: $e',
        backgroundColor: Colors.red[700]!,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ⭐ SAVE CLASSIFIED DATA TO DATABASE
  Future<void> _saveClassifiedData(
    Map<String, dynamic> data,
    String rawText,
  ) async {
    try {
      final classification = VoiceClassification.fromJson(data, rawText);
      final repo = VoiceActionRepository();

      await repo.saveVoiceAction(classification);

      if (!mounted) return;

      if (classification.type == 'task') {
        context.read<TaskProvider>().loadTasks();
      } else if (classification.type == 'event') {
        context.read<CalendarProvider>().loadEvents();
      } else {
        context.read<NotesProvider>().loadNotes();
      }
    } catch (e) {
      debugPrint('Save error: $e');
      rethrow;
    }
  }

  // ⭐ MIC TAP
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

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final speech = context.watch<SpeechProvider>();

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

      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar with Submit Button
              Padding(
                padding: EdgeInsets.only(
                  top: 50.h,
                  left: 16.w,
                  right: 16.w,
                  bottom: 12.h,
                ),
                child: Column(
                  children: [
                    Container(
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
                          hintText: "Write or attach your plan...",
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
                              color: AppColors.green,
                              width: 0.8.w,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.r),
                            borderSide: BorderSide(
                              color: AppColors.green,
                              width: 0.8.w,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.r),
                            borderSide: BorderSide(
                              color: AppColors.green,
                              width: 0.8.w,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 14.h,
                          ),
                        ),
                        // maxLines: 3,
                        onSubmitted: (_) => _processTextInput(),
                      ),
                    ),

                    // File name display & Submit button
                    if (_selectedFileName != null ||
                        _searchController.text.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          if (_selectedFileName != null)
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      size: 16.sp,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        _selectedFileName!,
                                        style: TextStyle(fontSize: 12.sp),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close, size: 16.sp),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFileName = null;
                                          _selectedFile = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_searchController.text.isNotEmpty &&
                              _selectedFileName == null)
                            Expanded(child: SizedBox()),
                          SizedBox(width: 8.w),
                          ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : (_selectedFile != null
                                      ? _processFile
                                      : _processTextInput),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                            child: _isProcessing
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                                      (isRecording
                                              ? Colors.red
                                              : AppColors.green)
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
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

          // Processing overlay
          // Processing overlay (without dark background)
          if (_isProcessing)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.black,
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

  void _showRecordingCompleteDialog(BuildContext context) {
    TopSnackBar.show(
      context,
      message: "Voice recognized — card appearing...",
      backgroundColor: AppColors.green,
    );
  }
}
