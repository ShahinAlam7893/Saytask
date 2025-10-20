import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                                    : Colors.black,
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

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                msg.eventTitle ?? "",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.keyboard_arrow_down,
                  color: Colors.white70, size: 20.sp),
            ],
          ),
          SizedBox(height: 4.h),

          // --- Date and Time Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tomorrow",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
              Text(
                "${msg.eventTime!.hour.toString().padLeft(2, '0')}:${msg.eventTime!.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // --- Call Me Row ---
          Row(
            children: [
              Icon(Icons.call, color: Colors.white70, size: 18.sp),
              SizedBox(width: 10.w),
              Text("Call Me", style: TextStyle(color: Colors.white70)),
              SizedBox(width: 10.w),
              AdvancedSwitch(
                controller: switchController,
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
                borderRadius: BorderRadius.circular(12.r),
                width: 40.w,
                height: 22.h,
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // --- Notification Row ---
          Row(
            children: [
              Icon(Icons.notifications_none, color: Colors.white70, size: 18.sp),
              SizedBox(width: 4.w),
              Text("At time of event", style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 4.h),

          // --- Note Row ---
          Row(
            children: [
              Icon(Icons.note_add_rounded,
                  color: Colors.white70, size: 18.sp),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  "Remember to ${msg.eventTitle?.toLowerCase()} tomorrow afternoon",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
