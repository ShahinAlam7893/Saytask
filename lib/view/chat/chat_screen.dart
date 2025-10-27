import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/chat_model.dart';
import 'package:saytask/repository/chat_service.dart';
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
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: Builder(
        builder: (context) => Scaffold(
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
                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.all(12.w),
                      itemCount: vm.messages.length,
                      itemBuilder: (context, index) {
                        final msg = vm.messages[vm.messages.length - 1 - index];
                        if (msg.type == MessageType.event &&
                            msg.eventTitle != null) {
                          return _buildEventCard(msg);
                        }
                        if (msg.message.isNotEmpty) {
                          return Align(
                            alignment: msg.type == MessageType.user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 16.w),
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              decoration: BoxDecoration(
                                color: msg.type == MessageType.user
                                    ? Colors.green
                                    : AppColors.secondaryTextColor,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                msg.message,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
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
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 16.w),
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
                          Provider.of<ChatViewModel>(context, listen: false)
                              .sendMessage(message);
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
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Event Card with flutter_advanced_switch
  Widget _buildEventCard(ChatMessage msg) {
    final ValueNotifier<bool> switchController =
    ValueNotifier<bool>(msg.callMe ?? false);
    bool isExpanded = false;
    String selectedReminder = msg.notification ?? "At time of event";

    return StatefulBuilder(
      builder: (context, setState) => Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.secondaryTextColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.grey.shade800, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title Row with Expand Icon ---
            Row(
              children: [
                Container(
                  width: 4.w,
                  height: 16.h,
                  color: Colors.green,
                ),
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
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),

            // --- Date & All-day Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tomorrow",
                    style: TextStyle(color: AppColors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                Text("All-day",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              ],
            ),
            SizedBox(height: 8.h),

            // --- Call Me Row ---
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
                AdvancedSwitch(
                  controller: switchController,
                  activeColor: Colors.green,
                  inactiveColor: Colors.grey,
                  borderRadius: BorderRadius.circular(12.r),
                  width: 50.w,
                  height: 22.h,
                ),
              ],
            ),
            // SizedBox(height: 4.h),

            // --- Notification Dropdown ---
            Row(
              children: [
                Icon(Icons.notifications_none, color: Colors.white70, size: 18.sp),
                SizedBox(width: 4.w),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: Row(
                      children: [
                        // Dropdown (without underline)
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedReminder,
                            dropdownColor: Colors.grey[850],
                            icon: const SizedBox.shrink(), // Hide default icon
                            items: [
                              "At time of event",
                              "5 minutes before",
                              "10 minutes before",
                              "15 minutes before",
                              "30 minutes before",
                              "1 hour before",
                              "2 hours before",
                              "13:00, 1 day before",
                              "None",
                            ].map((e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e, style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                                  if (e == selectedReminder)
                                    const Icon(Icons.check, color: Colors.green, size: 18),
                                ],
                              ),
                            ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedReminder = val);
                            },
                          ),
                        ),
                        // Custom dropdown arrow icon at trailing
                        Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22.sp),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 8.h),

            // --- Note Row ---
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
            SizedBox(height: 8.h),

            // --- Expandable Content ---
            if (isExpanded) ...[
              // --- Delete Button ---

              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: Text("Delay +1 hour"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text("Call me"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text("Remind 30 min before"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Provider.of<ChatViewModel>(context, listen: false)
                          .deleteMessage(msg);
                    },
                    icon: Icon(Icons.delete_outline, color: AppColors.white, size: 20.sp),
                  ),
                  IconButton(
                    onPressed: () {
                      // context.pushNamed('editEvent', extra: currentEvent);
                    },
                    icon: Icon(Icons.edit, color: AppColors.white, size: 20.sp),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}