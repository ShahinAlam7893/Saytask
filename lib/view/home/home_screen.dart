import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/core/api_endpoints.dart';
import 'package:saytask/main.dart' as TtsHelper;
import 'package:saytask/repository/settings_service.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/repository/voice_action_repository.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/service/local_storage_service.dart';
import 'package:saytask/utils/reminder_call_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  // ─── Card state after processing ───
  bool _showResultCard = false;
  VoiceClassification? _processedClassification;
  String _processedRawText = "";
  String _processedType = "";

  // Card internal state (exact match to SpeackEventCard)
  late ValueNotifier<bool> _cardCallMeController;
  bool _cardIsExpanded = false;
  bool _cardIsEditing = false;
  bool _cardIsSaving = false;

  late String _cardTitle;
  late String _cardNote;
  late String _cardSelectedReminder;
  late DateTime _cardEventDateTime;

  late TextEditingController _cardTitleController;
  late TextEditingController _cardNoteController;

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

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
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

      await _processFile();
    }
  }

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
        final classification = VoiceClassification.fromJson(data, text);

        _showCard(classification, text);
        _searchController.clear();
      } else {
        throw Exception("Classification failed");
      }
    } catch (e) {
      TopSnackBar.show(
        context,
        message: 'Failed to process: $e',
        backgroundColor: Colors.red[700]!,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() => _isProcessing = true);

    try {
      await LocalStorageService.init();
      final token = LocalStorageService.token;
      if (token == null) throw Exception("Not authenticated");

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
          final classification = VoiceClassification.fromJson(
            classifiedData,
            summary,
          );

          _showCard(classification, summary);
          setState(() {
            _selectedFileName = null;
            _selectedFile = null;
          });
        }
      } else {
        throw Exception("File processing failed");
      }
    } catch (e) {
      TopSnackBar.show(
        context,
        message: 'Failed to process file',
        backgroundColor: Colors.red[700]!,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showCard(VoiceClassification classification, String rawText) {
    setState(() {
      _processedClassification = classification;
      _processedRawText = rawText;
      _processedType = classification.type;
      _showResultCard = true;

      _cardTitle = classification.title.isEmpty
          ? "New Item"
          : classification.title;
      _cardNote = classification.description?.isNotEmpty == true
          ? classification.description!
          : rawText;
      _cardSelectedReminder = "At time of event"; 
      _cardCallMeController = ValueNotifier<bool>(classification.callMe);

      _cardTitleController = TextEditingController(text: _cardTitle);
      _cardNoteController = TextEditingController(text: _cardNote);

      if (classification.date != null) {
        final date = DateTime.parse(classification.date!);
        final hour = classification.time != null
            ? int.parse(classification.time!.split(':')[0])
            : 10;
        final minute = classification.time != null
            ? int.parse(classification.time!.split(':')[1])
            : 0;
        _cardEventDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
      } else {
        _cardEventDateTime = DateTime.now().add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _saveFromCard() async {
    if (_processedClassification == null) return;

    setState(() => _cardIsSaving = true);

    try {
      final title = _cardTitleController.text.trim().isEmpty
          ? "New Item"
          : _cardTitleController.text.trim();
      final description = _cardNoteController.text.trim();

      final updatedClassification = VoiceClassification(
        type: _processedType,
        title: title,
        description: description,
        date: _processedClassification!.date,
        time: _processedClassification!.time,
        callMe: _cardCallMeController.value,
        reminder: _cardSelectedReminder,
        rawText: _processedRawText,
        tags: _processedClassification!.tags,
        location: _processedClassification!.location,
        isAllDay: _processedClassification!.isAllDay,
      );

      final repo = VoiceActionRepository();
      await repo.saveVoiceAction(updatedClassification);

      if (_cardCallMeController.value) {
        final now = DateTime.now();
        var delay = _cardEventDateTime.difference(now);

        if (delay.isNegative || delay.inSeconds < 10) {
          delay = Duration.zero;
        }

        Future.delayed(delay, () async {
          try {
            final reminderText = description.isNotEmpty
                ? "$title. $description"
                : title;

            await ReminderCallHelper.showReminderCall(
              taskId: "home-${DateTime.now().millisecondsSinceEpoch}",
              itemId: "home-item",
              taskTitle: title,
              reminderMessage: reminderText,
              autoDeclineAfterSeconds: 60,
            );

            await TtsHelper.speakReminder(reminderText);
          } catch (e) {
            print("Home card call failed: $e");
          }
        });
      }

      setState(() => _showResultCard = false);

      TopSnackBar.show(
        context,
        message: "Saved successfully!",
        backgroundColor: Colors.green[700]!,
      );
    } catch (e) {
      TopSnackBar.show(
        context,
        message: "Save failed: $e",
        backgroundColor: Colors.red[700]!,
      );
    } finally {
      setState(() => _cardIsSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final speech = context.watch<SpeechProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
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

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
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
                          onSubmitted: (_) => _processTextInput(),
                        ),
                      ),

                      if (_selectedFileName != null ||
                          _searchController.text.isNotEmpty) ...[
                        SizedBox(height: 12.h),
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
                                        onPressed: () => setState(() {
                                          _selectedFileName = null;
                                          _selectedFile = null;
                                        }),
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
                                      child: const CircularProgressIndicator(
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
                                color: speech.isListening
                                    ? Colors.red
                                    : AppColors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (speech.isListening
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
                                speech.isListening ? Icons.stop : Icons.mic,
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

                        SizedBox(
                          height: 60.h,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: speech.isListening
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


            if (_showResultCard && _processedClassification != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showResultCard = false),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 6.h,
                            horizontal: 12.w,
                          ),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryTextColor,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _cardIsExpanded = !_cardIsExpanded,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(12.w),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4.w,
                                          height: 16.h,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: _cardIsEditing
                                              ? TextField(
                                                  controller:
                                                      _cardTitleController,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    color: Colors.white,
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  cursorColor: Colors.white,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                  ),
                                                )
                                              : Text(
                                                  _cardTitleController.text,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    color: Colors.white,
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                        Icon(
                                          _cardIsExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                          color: Colors.white,
                                          size: 26.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'EEE, d MMM',
                                        ).format(_cardEventDateTime),
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(_cardEventDateTime),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.call,
                                            color: Colors.white70,
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            "Call Me",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 60.w,
                                        height: 30.h,
                                        child: AdvancedSwitch(
                                          controller: _cardCallMeController,
                                          activeColor: Colors.green,
                                          inactiveColor: Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_none,
                                        color: Colors.white70,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _cardSelectedReminder,
                                            isExpanded: true,
                                            dropdownColor: Colors.grey[850],
                                            icon: const SizedBox.shrink(),
                                            items:
                                                [
                                                      "At time of event",
                                                      "5 minutes before",
                                                      "10 minutes before",
                                                      "15 minutes before",
                                                      "30 minutes before",
                                                      "1 hour before",
                                                      "2 hours before",
                                                      "None",
                                                    ]
                                                    .map(
                                                      (e) => DropdownMenuItem(
                                                        value: e,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              e,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 14.sp,
                                                              ),
                                                            ),
                                                            if (e ==
                                                                _cardSelectedReminder)
                                                              const Icon(
                                                                Icons.check,
                                                                color: Colors
                                                                    .green,
                                                                size: 18,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(
                                                  () => _cardSelectedReminder =
                                                      val,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white70,
                                        size: 26.sp,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),

                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.note_add_rounded,
                                        color: Colors.white70,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: _cardIsEditing
                                            ? TextField(
                                                controller: _cardNoteController,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14.sp,
                                                ),
                                                maxLines: 4,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                ),
                                              )
                                            : Text(
                                                _cardNoteController.text,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14.sp,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_cardIsExpanded) ...[
                                  SizedBox(height: 12.h),
                                  Center(
                                    child: Wrap(
                                      spacing: 8.w,
                                      runSpacing: 8.h,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _buildMiniButton(
                                          "Delay +1 hr",
                                          Icons.access_time,
                                          () {
                                            setState(
                                              () => _cardEventDateTime =
                                                  _cardEventDateTime.add(
                                                    const Duration(hours: 1),
                                                  ),
                                            );
                                            TopSnackBar.show(
                                              context,
                                              message: 'Time delayed by 1 hour',
                                              backgroundColor:
                                                  Colors.green[700]!,
                                            );
                                          },
                                        ),
                                        _buildMiniButton(
                                          "Call Me",
                                          Icons.call,
                                          () {
                                            _cardCallMeController.value = true;
                                            TopSnackBar.show(
                                              context,
                                              message: 'Call reminder enabled',
                                              backgroundColor:
                                                  Colors.green[700]!,
                                            );
                                          },
                                        ),
                                        _buildMiniButton(
                                          "Remind 30 min",
                                          Icons.notifications_active,
                                          () {
                                            setState(
                                              () => _cardSelectedReminder =
                                                  "30 minutes before",
                                            );
                                            TopSnackBar.show(
                                              context,
                                              message:
                                                  'Reminder set to 30 minutes before',
                                              backgroundColor:
                                                  Colors.green[700]!,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () => setState(
                                          () => _showResultCard = false,
                                        ),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.white,
                                          size: 22.sp,
                                        ),
                                      ),
                                      SizedBox(width: 40.w),
                                      IconButton(
                                        onPressed: () {
                                          setState(
                                            () => _cardIsEditing =
                                                !_cardIsEditing,
                                          );
                                        },
                                        icon: Icon(
                                          _cardIsEditing
                                              ? Icons.check
                                              : Icons.edit,
                                          color: AppColors.white,
                                          size: 22.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                SizedBox(height: 12.h),
                                if (_cardIsSaving)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3.0,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        "Saving...",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _saveFromCard,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 40.w,
                                          vertical: 10.h,
                                        ),
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25.r,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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

  Widget _buildMiniButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14.sp, color: Colors.white),
      label: Text(
        text,
        style: TextStyle(fontSize: 11.sp, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(0, 32.h),
      ),
    );
  }

  void _showRecordingCompleteDialog(BuildContext context) {
    TopSnackBar.show(
      context,
      message: "Voice recognized — card appearing...",
      backgroundColor: AppColors.green,
    );
  }

  Future<void> _onMicTap() async {
    final speech = context.read<SpeechProvider>();

    if (speech.isListening) {
      await speech.stopListening();
      _showRecordingCompleteDialog(context);
    } else {
      final started = await speech.startListening();
      if (!started) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot start speech recognition')),
        );
      }
    }
  }
}




// // lib/view/home/home_screen.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:saytask/core/api_endpoints.dart';
// import 'package:saytask/main.dart' as TtsHelper;
// import 'package:saytask/repository/calendar_service.dart';
// import 'package:saytask/repository/notes_service.dart';
// import 'package:saytask/repository/settings_service.dart';
// import 'package:saytask/repository/speech_provider.dart';
// import 'package:saytask/repository/today_task_service.dart';
// import 'package:saytask/repository/voice_action_repository.dart';
// import 'package:saytask/res/color.dart';
// import 'package:saytask/res/components/top_snackbar.dart';
// import 'package:saytask/service/local_storage_service.dart';
// import 'package:saytask/utils/reminder_call_helper.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController _searchController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   String? _selectedFileName;
//   File? _selectedFile;
//   bool _isProcessing = false;
//   bool _callMeEnabled = false;           // New: tracks Call Me switch
// DateTime? _classifiedEventTime;        // Store parsed time from classification
// String? _classifiedItemId;

//   late final AnimationController _animationController;
//   late final Animation<double> _scaleAnimation;

//   Timer? _typingTimer;
//   String? _displayedHint = "";
//   int _hintIndex = 0;

//   final List<String> _preRecordingHints = [
//     "Meeting today at 10 AM with Zen...",
//     "Set a medication reminder for 8 PM...",
//     "Plan weekend trip to the mountains...",
//     "Buy groceries on the way home...",
//   ];

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);

//     _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _startHintTypingAnimation();
//   }

//   void _startHintTypingAnimation() {
//     _typingTimer?.cancel();
//     _displayedHint = "";
//     int charIndex = 0;
//     String fullHint = _preRecordingHints[_hintIndex];

//     _typingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
//       if (!mounted) return;

//       if (charIndex < fullHint.length) {
//         setState(() {
//           _displayedHint = fullHint.substring(0, charIndex + 1);
//         });
//         charIndex++;
//       } else {
//         timer.cancel();
//         Future.delayed(const Duration(seconds: 2), () {
//           if (!mounted) return;
//           setState(() {
//             _hintIndex = (_hintIndex + 1) % _preRecordingHints.length;
//           });
//           _startHintTypingAnimation();
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _animationController.dispose();
//     _typingTimer?.cancel();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final file = File(result.files.single.path!);
//       setState(() {
//         _selectedFileName = result.files.single.name;
//         _selectedFile = file;
//       });

//       TopSnackBar.show(
//         context,
//         message: 'File selected: ${result.files.single.name}',
//         backgroundColor: Colors.green[700]!,
//       );

//       // Auto-process file
//       await _processFile();
//     }
//   }

//   // ⭐ PROCESS TEXT INPUT
//   Future<void> _processTextInput() async {
//     final text = _searchController.text.trim();
//     if (text.isEmpty) {
//       TopSnackBar.show(
//         context,
//         message: 'Please enter some text',
//         backgroundColor: Colors.orange[700]!,
//       );
//       return;
//     }

//     setState(() => _isProcessing = true);

//     try {
//       await LocalStorageService.init();
//       final token = LocalStorageService.token;
//       if (token == null) throw Exception("Not authenticated");

//       // Classify text using chatbot/classify endpoint
//       final response = await http.post(
//         Uri.parse('${Urls.baseUrl}chatbot/classify/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({"message": text}),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as Map<String, dynamic>;
//         await _saveClassifiedData(data, text);

//         _searchController.clear();
//         setState(() => _selectedFileName = null);

//         if (!mounted) return;
//         TopSnackBar.show(
//           context,
//           message: 'Successfully created from text!',
//           backgroundColor: Colors.green[700]!,
//         );
//       } else {
//         throw Exception("Classification failed");
//       }
//     } catch (e) {
//       if (!mounted) return;
//       TopSnackBar.show(
//         context,
//         message: 'Failed to process: $e',
//         backgroundColor: Colors.red[700]!,
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }


//   Future<void> _processFile() async {
//     if (_selectedFile == null) return;

//     setState(() => _isProcessing = true);

//     try {
//       await LocalStorageService.init();
//       final token = LocalStorageService.token;
//       if (token == null) throw Exception("Not authenticated");

//       // Summarize document
//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${Urls.baseUrl}/chatbot/summarize-document/'),
//       );

//       request.headers['Authorization'] = 'Bearer $token';
//       request.files.add(
//         await http.MultipartFile.fromPath('file', _selectedFile!.path),
//       );
//       request.fields['custom_prompt'] =
//           'Extract tasks, events, and notes from this document';
//       request.fields['max_length'] = '500';

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final summary = data['summary'] as String;

//         // Classify summary
//         final classifyResponse = await http.post(
//           Uri.parse('${Urls.baseUrl}/chatbot/classify/'),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//           },
//           body: json.encode({"message": summary}),
//         );

//         if (classifyResponse.statusCode == 200) {
//           final classifiedData =
//               json.decode(classifyResponse.body) as Map<String, dynamic>;
//           await _saveClassifiedData(classifiedData, summary);

//           setState(() {
//             _selectedFileName = null;
//             _selectedFile = null;
//           });

//           if (!mounted) return;
//           TopSnackBar.show(
//             context,
//             message: 'Successfully created from file!',
//             backgroundColor: Colors.green[700]!,
//           );
//         }
//       } else {
//         throw Exception("File processing failed");
//       }
//     } catch (e) {
//       if (!mounted) return;
//       TopSnackBar.show(
//         context,
//         message: 'Failed to process file',
//         // message: 'Failed to process file: $e',
//         backgroundColor: Colors.red[700]!,
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }


// Future<void> _saveClassifiedData(
//   Map<String, dynamic> data,
//   String rawText,
// ) async {
//   try {
//     final classification = VoiceClassification.fromJson(data, rawText);
//     final repo = VoiceActionRepository();

//     String? createdItemId;

//     await repo.saveVoiceAction(classification);

//     // Capture real item ID and event time (adjust based on type)
//     if (classification.type == 'event' || classification.type == 'task') {
//       // If backend returns ID in response, capture it
//       // For simplicity, we assume saveVoiceAction returns response with 'id'
//       // If not, use temp ID or fetch latest after load
//       createdItemId = "temp-${DateTime.now().millisecondsSinceEpoch}"; // fallback

//       // Parse event/task time for local scheduling
//       if (classification.date != null && classification.time != null) {
//         final date = DateTime.parse(classification.date!);
//         final parts = classification.time!.split(':');
//         final hour = int.parse(parts[0]);
//         final minute = int.parse(parts[1]);
//         _classifiedEventTime = DateTime(date.year, date.month, date.day, hour, minute);
//       }
//     }

//     if (!mounted) return;

//     if (classification.type == 'task') {
//       context.read<TaskProvider>().loadTasks();
//     } else if (classification.type == 'event') {
//       context.read<CalendarProvider>().loadEvents();
//     } else {
//       context.read<NotesProvider>().loadNotes();
//     }

//     // ──────────────────────────────────────────────────────────────
//     // LOCAL CALL SCHEDULING — same as voice/chat card
//     // ──────────────────────────────────────────────────────────────
//     if (_callMeEnabled && _classifiedEventTime != null) {
//       final now = DateTime.now();
//       var delay = _classifiedEventTime!.difference(now);

//       if (delay.isNegative || delay.inSeconds < 10) {
//         delay = Duration.zero;
//         print("Home call time passed/close — triggering NOW");
//       }

//       Future.delayed(delay, () async {
//         try {
//           final reminderText = rawText.isNotEmpty ? rawText : classification.title;

//           await ReminderCallHelper.showReminderCall(
//             taskId: createdItemId ?? "home-${DateTime.now().millisecondsSinceEpoch}",
//             itemId: createdItemId ?? "home-item",
//             taskTitle: classification.title,
//             reminderMessage: reminderText,
//             autoDeclineAfterSeconds: 60,
//           );

//           await TtsHelper.speakReminder(reminderText);
//           print("Home local call TRIGGERED for: ${classification.title} at $_classifiedEventTime");
//         } catch (e) {
//           print("Home local call failed: $e");
//         }
//       });

//       print("Home call scheduled locally — delay: ${delay.inMinutes} min for: ${classification.title}");
//     }
//     // ──────────────────────────────────────────────────────────────

//     // Reset Call Me switch after save
//     setState(() => _callMeEnabled = false);
//   } catch (e) {
//     debugPrint('Save error: $e');
//     rethrow;
//   }
// }
//   // ⭐ SAVE CLASSIFIED DATA TO DATABASE
//   // Future<void> _saveClassifiedData(
//   //   Map<String, dynamic> data,
//   //   String rawText,
//   // ) async {
//   //   try {
//   //     final classification = VoiceClassification.fromJson(data, rawText);
//   //     final repo = VoiceActionRepository();

//   //     await repo.saveVoiceAction(classification);

//   //     if (!mounted) return;

//   //     if (classification.type == 'task') {
//   //       context.read<TaskProvider>().loadTasks();
//   //     } else if (classification.type == 'event') {
//   //       context.read<CalendarProvider>().loadEvents();
//   //     } else {
//   //       context.read<NotesProvider>().loadNotes();
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Save error: $e');
//   //     rethrow;
//   //   }
//   // }

//   Future<void> _onMicTap() async {
//     final speech = context.read<SpeechProvider>();

//     if (speech.isListening) {
//       // Stop listening
//       await speech.stopListening();
//       _showRecordingCompleteDialog(context);
//     } else {
//       // Start listening
//       final started = await speech.startListening();
//       if (!started) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Cannot start speech recognition')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final settingsViewModel = context.watch<SettingsViewModel>();
//     final speech = context.watch<SpeechProvider>();

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         toolbarHeight: 70.h,
//         automaticallyImplyLeading: false,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             SvgPicture.asset(
//               'assets/images/Saytask_logo.svg',
//               height: 24.h,
//               width: 100.w,
//             ),
//             IconButton(
//               icon: Icon(
//                 Icons.settings_outlined,
//                 color: Colors.black,
//                 size: 24.sp,
//               ),
//               onPressed: () => context.push('/settings'),
//             ),
//           ],
//         ),
//       ),

//       body: SafeArea(
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.only(
//                     top: 50.h,
//                     left: 16.w,
//                     right: 16.w,
//                     bottom: 12.h,
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12.r),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.3),
//                               spreadRadius: 1,
//                               blurRadius: 6,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: TextField(
//                           controller: _searchController,
//                           decoration: InputDecoration(
//                             hintText: "Write or attach your plan...",
//                             hintStyle: TextStyle(
//                               fontFamily: 'Inter',
//                               fontSize: 14.sp,
//                               color: Colors.grey[400],
//                             ),
//                             filled: true,
//                             fillColor: Colors.grey[50],
//                             suffixIcon: IconButton(
//                               onPressed: _pickFile,
//                               icon: Icon(
//                                 Icons.attach_file,
//                                 color: Colors.grey[600],
//                                 size: 20.sp,
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(18.r),
//                               borderSide: BorderSide(
//                                 color: AppColors.green,
//                                 width: 0.8.w,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(18.r),
//                               borderSide: BorderSide(
//                                 color: AppColors.green,
//                                 width: 0.8.w,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(18.r),
//                               borderSide: BorderSide(
//                                 color: AppColors.green,
//                                 width: 0.8.w,
//                               ),
//                             ),
//                             contentPadding: EdgeInsets.symmetric(
//                               horizontal: 20.w,
//                               vertical: 14.h,
//                             ),
//                           ),
//                           // maxLines: 3,
//                           onSubmitted: (_) => _processTextInput(),
//                         ),
//                       ),

//                       // File name display & Submit button
//                       if (_selectedFileName != null ||
//                           _searchController.text.isNotEmpty) ...[
//                         SizedBox(height: 8.h),
//                         Row(
//                           children: [
//                             if (_selectedFileName != null)
//                               Expanded(
//                                 child: Container(
//                                   padding: EdgeInsets.all(8.w),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue[50],
//                                     borderRadius: BorderRadius.circular(8.r),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         Icons.insert_drive_file,
//                                         size: 16.sp,
//                                         color: Colors.blue,
//                                       ),
//                                       SizedBox(width: 4.w),
//                                       Expanded(
//                                         child: Text(
//                                           _selectedFileName!,
//                                           style: TextStyle(fontSize: 12.sp),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: Icon(Icons.close, size: 16.sp),
//                                         onPressed: () {
//                                           setState(() {
//                                             _selectedFileName = null;
//                                             _selectedFile = null;
//                                           });
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             if (_searchController.text.isNotEmpty &&
//                                 _selectedFileName == null)
//                               Expanded(child: SizedBox()),
//                             SizedBox(width: 8.w),
//                             ElevatedButton(
//                               onPressed: _isProcessing
//                                   ? null
//                                   : (_selectedFile != null
//                                         ? _processFile
//                                         : _processTextInput),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.green,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12.r),
//                                 ),
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 16.w,
//                                   vertical: 12.h,
//                                 ),
//                               ),
//                               child: _isProcessing
//                                   ? SizedBox(
//                                       width: 16.w,
//                                       height: 16.h,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : Icon(
//                                       Icons.send,
//                                       color: Colors.white,
//                                       size: 20.sp,
//                                     ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),

//                 // Mic Section
//                 Expanded(
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         ScaleTransition(
//                           scale: _scaleAnimation,
//                           child: GestureDetector(
//                             onTap: _onMicTap,
//                             child: Container(
//                               width: 160.w,
//                               height: 160.w,
//                               decoration: BoxDecoration(
//                                 color: speech.isListening
//                                     ? Colors.red
//                                     : AppColors.green,
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color:
//                                         (speech.isListening
//                                                 ? Colors.red
//                                                 : AppColors.green)
//                                             .withOpacity(0.4),
//                                     blurRadius: 25.r,
//                                     spreadRadius: 5.r,
//                                     offset: Offset(0, 4.h),
//                                   ),
//                                 ],
//                               ),
//                               child: Icon(
//                                 speech.isListening ? Icons.stop : Icons.mic,
//                                 color: Colors.white,
//                                 size: 60.sp,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 24.h),
//                         RichText(
//                           text: TextSpan(
//                             style: TextStyle(
//                               fontFamily: 'Inter',
//                               fontSize: 16.sp,
//                               color: Colors.black,
//                             ),
//                             children: [
//                               const TextSpan(text: 'Tap to '),
//                               WidgetSpan(
//                                 alignment: PlaceholderAlignment.middle,
//                                 child: SvgPicture.asset(
//                                   'assets/images/Saytask_logo_without_icon.svg',
//                                   height: 18.h,
//                                   width: 18.w,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Live Text / Hint
//                         SizedBox(
//                           height: 60.h,
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             child: speech.isListening
//                                 ? Padding(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 20.w,
//                                     ),
//                                     child: ListView(
//                                       controller: _scrollController,
//                                       scrollDirection: Axis.horizontal,
//                                       physics: const BouncingScrollPhysics(),
//                                       children: [
//                                         Center(
//                                           child: Text(
//                                             speech.text.isEmpty
//                                                 ? "Listening..."
//                                                 : speech.text,
//                                             style: TextStyle(
//                                               fontSize: 16.sp,
//                                               color: AppColors.black,
//                                               fontFamily: 'Inter',
//                                               fontWeight: FontWeight.w400,
//                                             ),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   )
//                                 : Center(
//                                     child: Text(
//                                       _displayedHint ?? "",
//                                       key: ValueKey(_displayedHint),
//                                       style: TextStyle(
//                                         fontSize: 16.sp,
//                                         color: AppColors.green,
//                                         fontStyle: FontStyle.italic,
//                                         fontFamily: 'Inter',
//                                         fontWeight: FontWeight.w400,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             if (_isProcessing)
//               Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const CircularProgressIndicator(
//                       color: AppColors.black,
//                       strokeWidth: 4,
//                     ),
//                     SizedBox(height: 16.h),
//                     Text(
//                       'Processing...',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),

//       floatingActionButton: settingsViewModel.enableAIChatbot
//           ? SizedBox(
//               width: 60.w,
//               height: 60.h,
//               child: FloatingActionButton(
//                 onPressed: () => context.push('/chat'),
//                 backgroundColor: AppColors.green,
//                 shape: const CircleBorder(),
//                 elevation: 4,
//                 child: Icon(Icons.chat, color: Colors.white, size: 28.sp),
//               ),
//             )
//           : null,
//     );
//   }

//   void _showRecordingCompleteDialog(BuildContext context) {
//     TopSnackBar.show(
//       context,
//       message: "Voice recognized — card appearing...",
//       backgroundColor: AppColors.green,
//     );
//   }
// }
