// lib/res/components/speak_screen/event_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/main.dart' as TtsHelper;
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/repository/voice_action_repository.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/utils/reminder_call_helper.dart';

class SpeackEventCard extends StatefulWidget {
  final Future<void> Function()? onSave;

  const SpeackEventCard({super.key, this.onSave});

  @override
  State<SpeackEventCard> createState() => _SpeackEventCardState();
}

class _SpeackEventCardState extends State<SpeackEventCard> {
  late ValueNotifier<bool> _callMeController;
  bool isExpanded = false;
  bool isEditing = false;
  bool _isSaving = false;

  late String _title;
  late String _note;
  late String _selectedReminder;
  late DateTime _eventDateTime;

  late TextEditingController _titleController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final cls = context.read<SpeechProvider>().lastClassification!;

    _title = cls.title.isEmpty ? "New Item" : cls.title;
    _note = cls.description?.isNotEmpty == true
        ? cls.description!
        : cls.rawText;
    // _selectedReminder = cls.reminder;
    _selectedReminder = "At time of event";
    _callMeController = ValueNotifier<bool>(cls.callMe);

    _titleController = TextEditingController(text: _title);
    _noteController = TextEditingController(text: _note);

    // Parse local DateTime from classification
    if (cls.date != null) {
      final date = DateTime.parse(cls.date!);
      final hour = cls.time != null ? int.parse(cls.time!.split(':')[0]) : 10;
      final minute = cls.time != null ? int.parse(cls.time!.split(':')[1]) : 0;
      _eventDateTime = DateTime(date.year, date.month, date.day, hour, minute);
    } else {
      _eventDateTime = DateTime.now().add(const Duration(hours: 1));
    }

    _callMeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _callMeController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  //DELAY +1 HOUR
  void _delayOneHour() {
    setState(() {
      _eventDateTime = _eventDateTime.add(const Duration(hours: 1));
    });
    TopSnackBar.show(
      context,
      message: 'Time delayed by 1 hour',
      backgroundColor: Colors.green[700]!,
    );
  }

  // SET CALL ME
  void _setCallMe() {
    _callMeController.value = true;
    TopSnackBar.show(
      context,
      message: 'Call reminder enabled',
      backgroundColor: Colors.green[700]!,
    );
  }

  //SET REMINDER TO 30 MIN
  void _setReminder30Min() {
    setState(() {
      _selectedReminder = "30 minutes before";
    });
    TopSnackBar.show(
      context,
      message: 'Reminder set to 30 minutes before',
      backgroundColor: Colors.green[700]!,
    );
  }

  List<Map<String, dynamic>> _buildReminders() {
    final reminders = <Map<String, dynamic>>[];

    if (_callMeController.value) {
      reminders.add({
        "time_before": 0,
        "types": ["notification", "call"],
      });
    }

    final minutesMap = {
      "At time of event": 0,
      "5 minutes before": 5,
      "10 minutes before": 10,
      "15 minutes before": 15,
      "30 minutes before": 30,
      "1 hour before": 60,
      "2 hours before": 120,
    };

    final minutes = minutesMap[_selectedReminder] ?? 0;

    if (minutes > 0 &&
        _selectedReminder != "At time of event" &&
        _selectedReminder != "None" &&
        _selectedReminder.isNotEmpty) {
      reminders.add({
        "time_before": minutes,
        "types": ["notification"],
      });
    }

    return reminders;
  }

  Future<void> _saveToDatabase() async {
    if (_isSaving) return; // Prevent double-tap

    setState(() => _isSaving = true);

    final cls = context.read<SpeechProvider>().lastClassification!;
    final repo = VoiceActionRepository();

    try {
      final startTimeStr = _eventDateTime.toUtc().toIso8601String();
      final title = _titleController.text.trim().isEmpty
          ? "New Item"
          : _titleController.text.trim();
      final description = _noteController.text.trim();

      String? createdItemId;

      if (cls.type == 'event') {
        final endTimeStr = _eventDateTime
            .add(const Duration(hours: 1))
            .toUtc()
            .toIso8601String();

        final response = await repo.createEvent({
          "title": title,
          "description": description,
          "event_datetime": startTimeStr,
          "start_time": startTimeStr,
          "end_time": endTimeStr,
          "reminders": _buildReminders().isNotEmpty ? _buildReminders() : [],
          "location_address": cls.location ?? "",
        });

        createdItemId = response['id'] as String?;

        if (!mounted) return;
        await context.read<CalendarProvider>().loadEvents();
      } else if (cls.type == 'task') {
        final response = await repo.createTask({
          "title": title,
          "description": description,
          "start_time": startTimeStr,
          "duration": 60,
          "tags": cls.tags ?? [],
          "reminders": _buildReminders(),
          "completed": false,
        });

        createdItemId = response['id'] as String?;

        if (!mounted) return;
        await context.read<TaskProvider>().loadTasks();
      } else {
        await repo.createNote(description);
        if (!mounted) return;
        await context.read<NotesProvider>().loadNotes();
      }

      // Local call scheduling (unchanged — already perfect)
      if (_callMeController.value) {
        final now = DateTime.now();
        var delay = _eventDateTime.difference(now);

        if (delay.isNegative || delay.inSeconds < 10) {
          delay = Duration.zero;
          print("Voice call time passed/close — triggering NOW");
        }

        Future.delayed(delay, () async {
          try {
            final reminderText = description.isNotEmpty
                ? "$title. $description"
                : title;

            await ReminderCallHelper.showReminderCall(
              taskId:
                  createdItemId ??
                  "voice-${DateTime.now().millisecondsSinceEpoch}",
              itemId: createdItemId ?? "voice-item",
              taskTitle: title,
              reminderMessage: reminderText,
              autoDeclineAfterSeconds: 60,
            );

            await TtsHelper.speakReminder(reminderText);
            print(
              "Voice local call TRIGGERED successfully for: $title at $_eventDateTime",
            );
          } catch (e) {
            print("Voice local call failed: $e");
          }
        });

        print(
          "Voice call scheduled locally — delay: ${delay.inMinutes} min (${delay.inSeconds} sec) for: $title at $_eventDateTime",
        );
      }

      if (!mounted) return;

      TopSnackBar.show(
        context,
        message: "Saved successfully!",
        backgroundColor: Colors.green[700]!,
      );

      context.read<SpeechProvider>().resetCardState();
    } catch (e) {
      if (!mounted) return;

      TopSnackBar.show(
        context,
        message: "Error: $e",
        backgroundColor: Colors.red[700]!,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Future<void> _saveToDatabase() async {
  //   final cls = context.read<SpeechProvider>().lastClassification!;
  //   final repo = VoiceActionRepository();

  //   try {
  //     final startTimeStr = _eventDateTime.toUtc().toIso8601String();
  //     final title = _titleController.text.trim().isEmpty
  //         ? "New Item"
  //         : _titleController.text.trim();
  //     final description = _noteController.text.trim();

  //     if (cls.type == 'event') {
  //       final endTimeStr = _eventDateTime
  //           .add(const Duration(hours: 1))
  //           .toUtc()
  //           .toIso8601String();

  //       await repo.createEvent({
  //         "title": title,
  //         "description": description,
  //         "event_datetime": startTimeStr,
  //         "start_time": startTimeStr,
  //         "end_time": endTimeStr,
  //         "reminders": _buildReminders().isNotEmpty ? _buildReminders() : [],
  //         "location_address": cls.location ?? "",
  //       });

  //       if (!mounted) return;
  //       await context.read<CalendarProvider>().loadEvents();
  //     } else if (cls.type == 'task') {
  //       await repo.createTask({
  //         "title": title,
  //         "description": description,
  //         "start_time": startTimeStr,
  //         "duration": 60,
  //         "tags": cls.tags ?? [],
  //         "reminders": _buildReminders(),
  //         "completed": false,
  //       });

  //       if (!mounted) return;
  //       await context.read<TaskProvider>().loadTasks();
  //     } else {
  //       await repo.createNote(description);

  //       if (!mounted) return;
  //       await context.read<NotesProvider>().loadNotes();
  //     }

  //     if (!mounted) return;

  //     TopSnackBar.show(
  //       context,
  //       message: "Saved successfully!",
  //       backgroundColor: Colors.green[700]!,
  //     );

  //     context.read<SpeechProvider>().resetCardState();
  //   } catch (e) {
  //     if (!mounted) return;

  //     TopSnackBar.show(
  //       context,
  //       message: "Error: $e",
  //       backgroundColor: Colors.red[700]!,
  //       duration: const Duration(seconds: 4),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final cls = context.watch<SpeechProvider>().lastClassification!;
    final dateText = DateFormat('EEE, d MMM').format(_eventDateTime);
    final timeText = DateFormat('h:mm a').format(_eventDateTime);

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
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
                  child: isEditing
                      ? TextField(
                          controller: _titleController,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Title",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                          onChanged: (v) => _title = v,
                        )
                      : Text(
                          _titleController.text,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 26.sp,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.call, color: Colors.white70, size: 18.sp),
                    SizedBox(width: 10.w),
                    Text(
                      "Call Me",
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
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
                Icon(
                  Icons.notifications_none,
                  color: Colors.white70,
                  size: 18.sp,
                ),
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
                                ].map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        if (e == _selectedReminder)
                                          const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                      ],
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
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                          size: 26.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // NOTE / DESCRIPTION
            Row(
              children: [
                Icon(
                  Icons.note_add_rounded,
                  color: Colors.white70,
                  size: 18.sp,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: _noteController,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                          maxLines: 4,
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Add note or description...",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                          onChanged: (v) => _note = v,
                        )
                      : Text(
                          _noteController.text,
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

            // EXPANDED SECTION
            if (isExpanded) ...[
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
                      _delayOneHour,
                    ),
                    _buildMiniButton("Call Me", Icons.call, _setCallMe),
                    _buildMiniButton(
                      "Remind 30 min",
                      Icons.notifications_active,
                      _setReminder30Min,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () =>
                        context.read<SpeechProvider>().resetCardState(),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.white,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 40.w),
                  IconButton(
                    onPressed: () {
                      setState(() => isEditing = !isEditing);
                      if (!isEditing) {
                        _title = _titleController.text;
                        _note = _noteController.text;
                      }
                    },
                    icon: Icon(
                      isEditing ? Icons.check : Icons.edit,
                      color: AppColors.white,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ],

            // SAVE BUTTON
            SizedBox(height: 12.h),
            if (_isSaving)
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
                    ),
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton(
                  onPressed: _saveToDatabase,
                  style: ElevatedButton.styleFrom(
                    // minimumSize: Size(double.infinity, 48.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 40.w,
                      vertical: 10.h,
                    ),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
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
}
