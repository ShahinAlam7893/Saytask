// lib/screens/chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/chat_model.dart';
import 'package:saytask/repository/chat_service.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/top_snackbar.dart';
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

  void _refreshProvidersAfterAIResponse() {
    if (!mounted) return;
    
    context.read<CalendarProvider>().loadEvents();
    context.read<TaskProvider>().loadTasks();
    context.read<NotesProvider>().loadNotes();
    
    debugPrint('✅ Providers refreshed');
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();

    final vm = context.read<ChatViewModel>();
    await vm.sendMessage(message);

    _refreshProvidersAfterAIResponse();
  }

  @override
  Widget build(BuildContext context) {
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

                    if ((msg.type == MessageType.event || msg.type == MessageType.task) && 
                        msg.eventTitle != null) {
                      return _EventTaskCard(
                        key: ValueKey(msg.messageId ?? index),
                        message: msg,
                        onUpdate: _refreshProvidersAfterAIResponse,
                      );
                    }

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
                    onSubmitted: (_) => _sendMessage(),
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
                  onTap: _sendMessage,
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════
// STATEFUL EVENT/TASK CARD WITH FULL EDITING & DATABASE UPDATE
// ════════════════════════════════════════════════════════════════
class _EventTaskCard extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onUpdate;

  const _EventTaskCard({
    super.key,
    required this.message,
    required this.onUpdate,
  });

  @override
  State<_EventTaskCard> createState() => _EventTaskCardState();
}

class _EventTaskCardState extends State<_EventTaskCard> {
  late ValueNotifier<bool> _callMeController;
  late bool _isExpanded;
  late bool _isEditing;
  late String _selectedReminder;
  late DateTime _eventTime;
  
  late TextEditingController _titleController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    
    _callMeController = ValueNotifier<bool>(widget.message.callMe ?? false);
    _isExpanded = false;
    _isEditing = false;
    _selectedReminder = widget.message.notification ?? "At time of event";
    _eventTime = widget.message.eventTime ?? DateTime.now().add(const Duration(hours: 1));
    
    _titleController = TextEditingController(text: widget.message.eventTitle ?? "");
    _noteController = TextEditingController(text: widget.message.note ?? "");

    // Listen to switch changes
    _callMeController.addListener(_onCallMeChanged);
  }

  @override
  void dispose() {
    _callMeController.removeListener(_onCallMeChanged);
    _callMeController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onCallMeChanged() {
    setState(() {}); // Rebuild when switch changes
  }

  // ⭐ DELAY +1 HOUR
  void _delayOneHour() {
    setState(() {
      _eventTime = _eventTime.add(const Duration(hours: 1));
    });
    TopSnackBar.show(
      context,
      message: 'Time delayed by 1 hour',
      backgroundColor: Colors.green,
    );
  }

  // ⭐ SET CALL ME
  void _setCallMe() {
    _callMeController.value = true;
    TopSnackBar.show(
      context,
      message: 'Call reminder enabled',
      backgroundColor: Colors.green,
    );
  }

  // ⭐ SET REMINDER TO 30 MIN
  void _setReminder30Min() {
    setState(() {
      _selectedReminder = "30 minutes before";
    });
    TopSnackBar.show(
      context,
      message: 'Reminder set to 30 minutes before',
      backgroundColor: Colors.green,
    );
  }

  // ⭐ SAVE CHANGES TO DATABASE
  Future<void> _saveChanges() async {
    setState(() => _isEditing = false);

    final vm = context.read<ChatViewModel>();

    // Update local message
    vm.editEventMessage(
      widget.message,
      newTitle: _titleController.text.trim(),
      newTime: _eventTime,
      newNotification: _selectedReminder,
      newNote: _noteController.text.trim(),
    );

    // Create updated message object
    final updatedMessage = ChatMessage(
      message: widget.message.message,
      type: widget.message.type,
      createdAt: widget.message.createdAt,
      responseType: widget.message.responseType,
      eventTime: _eventTime,
      eventTitle: _titleController.text.trim(),
      callMe: _callMeController.value,
      notification: _selectedReminder,
      note: _noteController.text.trim(),
      messageId: widget.message.messageId,
    );

    try {
      // ⭐ SAVE TO DATABASE
      await vm.saveEditedMessage(updatedMessage);

      if (!mounted) return;

      TopSnackBar.show(
        context,
        message: 'Changes saved to database',
        backgroundColor: Colors.green,
      );
      

      // Refresh providers
      widget.onUpdate();
    } catch (e) {
      if (!mounted) return;
      TopSnackBar.show(
        context,
        message: 'Failed to save changes: $e',
        backgroundColor: Colors.red,
      );
    
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, d MMM').format(_eventTime);
    final timeText = DateFormat('h:mm a').format(_eventTime);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
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
            // TITLE ROW
            Row(
              children: [
                Container(width: 4.w, height: 16.h, color: Colors.green),
                SizedBox(width: 8.w),
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _titleController,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Title",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        )
                      : Text(
                          _titleController.text,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Icon(
                      _isExpanded
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

            // DATE & TIME ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeText,
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // CALL ME SWITCH
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
                    controller: _callMeController,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),

            // REMINDER DROPDOWN
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
                            value: _selectedReminder,
                            dropdownColor: Colors.grey[850],
                            icon: const SizedBox.shrink(),
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
                            ].map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedReminder = val);
                              }
                            },
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

            // NOTE/DESCRIPTION - Show only description or original user message
            Row(
              children: [
                Icon(Icons.note_add_rounded, color: Colors.white70, size: 18.sp),
                SizedBox(width: 4.w),
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _noteController,
                          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Add note...",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        )
                      : Text(
                          widget.message.note?.isNotEmpty == true
                              ? _noteController.text
                              : widget.message.message,
                          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),

            // EXPANDED SECTION
            if (_isExpanded) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniActionButton("Delay +1 hr", Icons.access_time, _delayOneHour),
                  _buildMiniActionButton("Call Me", Icons.call, _setCallMe),
                  _buildMiniActionButton("Remind 30 min", Icons.notifications_active, _setReminder30Min),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      context.read<ChatViewModel>().deleteMessage(widget.message);
                      TopSnackBar.show(
                        context,
                        message: 'Item removed from chat',
                        backgroundColor: Colors.red[700]!,
                      );
                    
                    },
                    icon: Icon(Icons.delete_outline, color: AppColors.white, size: 22.sp),
                  ),
                  SizedBox(width: 40.w),
                  IconButton(
                    onPressed: () {
                      if (_isEditing) {
                        _saveChanges();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    icon: Icon(
                      _isEditing ? Icons.check : Icons.edit,
                      color: AppColors.white,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildMiniActionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14.sp, color: Colors.white),
      label: Text(text, style: TextStyle(fontSize: 11.sp, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(0, 32.h),
      ),
    );
  }
}