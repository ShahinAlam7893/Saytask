// lib/screens/chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/chat_model.dart';
import 'package:saytask/repository/chat_service.dart'; // Your ChatViewModel
import 'package:saytask/res/color.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Load chat history ONCE when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChatViewModel>();
      if (vm.messages.isEmpty) {
        vm.fetchHistory();
      }
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED ChangeNotifierProvider — Now using global singleton from main.dart
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(12.w),
          child: Container(
            height: 24.h,
            width: 24.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 16.sp),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Chatbot',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading && vm.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(12.w),
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final msg = vm.messages[vm.messages.length - 1 - index];

                    // EVENT CARD
                    if (msg.type == MessageType.event && msg.eventTitle != null) {
                      return _buildEventCard(msg);
                    }

                    // NORMAL MESSAGES
                    if (msg.message.isNotEmpty) {
                      return Align(
                        alignment: msg.type == MessageType.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                          margin: EdgeInsets.symmetric(vertical: 4.h),
                          decoration: BoxDecoration(
                            color: msg.type == MessageType.user
                                ? Colors.green
                                : AppColors.secondaryTextColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            msg.message,
                            style: TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),

          // INPUT BAR
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Write your question here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: CircleAvatar(
                    radius: 25.r,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    final message = _controller.text.trim();
                    if (message.isNotEmpty) {
                      context.read<ChatViewModel>().sendMessage(message);
                      _controller.clear();
                      _focusNode.unfocus();
                    }
                  },
                  child: CircleAvatar(
                    radius: 25.r,
                    backgroundColor: Colors.green,
                    child: const Icon(TablerIcons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  // YOUR EXACT EVENT CARD — 100% UNCHANGED
  Widget _buildEventCard(ChatMessage msg) {
    final ValueNotifier<bool> switchController = ValueNotifier<bool>(msg.callMe ?? false);
    bool isExpanded = false;
    String selectedReminder = msg.notification ?? "At time of event";

    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        onTap: () => setState(() => isExpanded = !isExpanded),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 4.w, height: 16.h, color: Colors.green),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      msg.eventTitle ?? "",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isExpanded = !isExpanded),
                    child: Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tomorrow",
                    style: TextStyle(color: AppColors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                  Text("All-day", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.call, color: Colors.white70, size: 18.sp),
                      SizedBox(width: 10.w),
                      Text("Call Me", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                    ],
                  ),
                  SizedBox(
                    width: 60.w,
                    height: 30.h,
                    child: AdvancedSwitch(
                      controller: switchController,
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.notifications_none, color: Colors.white70, size: 18.sp),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedReminder,
                              dropdownColor: Colors.grey[850],
                              icon: const SizedBox.shrink(),
                              items: [
                                "At time of event", "5 minutes before", "10 minutes before",
                                "15 minutes before", "30 minutes before", "1 hour before",
                                "2 hours before", "13:00, 1 day before", "None",
                              ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Colors.white70, fontSize: 14.sp)))).toList(),
                              onChanged: (val) => val != null ? setState(() => selectedReminder = val) : null,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 26.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.note_add_rounded, color: Colors.white70, size: 18.sp),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      "Remember to ${msg.eventTitle?.toLowerCase()} tomorrow afternoon",
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniActionButton("Delay +1 hr", Icons.access_time),
                    _buildMiniActionButton("Call Me", Icons.call),
                    _buildMiniActionButton("Remind 30 min", Icons.notifications_active),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.read<ChatViewModel>().deleteMessage(msg),
                      icon: Icon(Icons.delete_outline, color: AppColors.white, size: 22.sp),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit feature coming soon!'), duration: Duration(seconds: 2)),
                        );
                      },
                      icon: Icon(Icons.edit, color: AppColors.white, size: 22.sp),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14.sp, color: Colors.white),
      label: Text(text, style: TextStyle(fontSize: 12.sp, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}