// lib/res/components/speak_screen/event_card.dart
// FINAL VERSION — ALL YOUR REQUIREMENTS MET

import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/repository/voice_action_repository.dart';
import 'package:saytask/res/components/top_snackbar.dart';

class SpeackEventCard extends StatefulWidget {
  const SpeackEventCard({super.key, required Future<Null> Function() onSave});

  @override
  State<SpeackEventCard> createState() => _SpeackEventCardState();
}

class _SpeackEventCardState extends State<SpeackEventCard> {
  final ValueNotifier<bool> _callMeController = ValueNotifier<bool>(false);
  bool isExpanded = false;
  bool isEditing = false;

  late String _title;
  late String _note;
  late String _selectedReminder;
  DateTime? _eventDateTime;

  late TextEditingController _titleController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final cls = context.read<SpeechProvider>().lastClassification!;

    _title = cls.title.isEmpty ? "New Item" : cls.title;
    _note = cls.description?.isNotEmpty == true
        ? cls.description!
        : cls.rawText; // ← Raw voice text
    _selectedReminder = cls.reminder;
    _callMeController.value = cls.callMe;

    _titleController = TextEditingController(text: _title);
    _noteController = TextEditingController(text: _note);

    // Parse local DateTime from classification
    if (cls.date != null) {
      final date = DateTime.parse(cls.date!);
      final hour = cls.time != null ? int.parse(cls.time!.split(':')[0]) : 10;
      final minute = cls.time != null ? int.parse(cls.time!.split(':')[1]) : 0;
      _eventDateTime = DateTime(date.year, date.month, date.day, hour, minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _delayOneHour() {
    if (_eventDateTime != null) {
      setState(() {
        _eventDateTime = _eventDateTime!.add(const Duration(hours: 1));
      });
      TopSnackBar.show(
        context,
        message: 'Time delayed by 1 hour',
        backgroundColor: Colors.green[700]!,
      );
    }
  }

  Map<String, dynamic> _getReminder() {
    final minutesMap = {
      "5 minutes before": 5,
      "10 minutes before": 10,
      "15 minutes before": 15,
      "30 minutes before": 30,
      "1 hour before": 60,
      "2 hours before": 120,
    };
    final minutes = minutesMap[_selectedReminder] ?? 0;
    if (minutes == 0) return {};
    return {
      "time_before": minutes,
      "types": _callMeController.value
          ? ["notification", "call"]
          : ["notification"],
    };
  }

  @override
  Widget build(BuildContext context) {
    final cls = context.watch<SpeechProvider>().lastClassification!;
    final dateText = cls.date == null
        ? "No date"
        : DateFormat('EEE, d MMM').format(DateTime.parse(cls.date!));
    final timeText = cls.isAllDay || cls.time == null ? "All-day" : cls.time!;

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
            // Title Row
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
                          _title,
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

            // Date & Time Row
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

            // Call Me Switch
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

            // Reminder Dropdown
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

            // Note / Description
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
                          _note,
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

            // Expanded Section
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
                    _buildMiniButton(
                      "Call Me",
                      Icons.call,
                      () => _callMeController.value = true,
                    ),
                    _buildMiniButton(
                      "Remind 30 min",
                      Icons.notifications_active,
                      () {
                        setState(() => _selectedReminder = "30 minutes before");
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

            // Save Button
            Center(
              child: SizedBox(
                height: 40.h,
                width: 120.w,
                child: ElevatedButton(
                  onPressed: () async {
                    final repo = VoiceActionRepository();
                    final reminder = _getReminder();
                    final startTime = _eventDateTime ?? DateTime.now();

                    final payload = {
                      "title": _title.trim().isEmpty
                          ? "New Item"
                          : _title.trim(),
                      "description": _note,
                      "start_time": startTime.toUtc().toIso8601String(),
                      if (reminder.isNotEmpty) "reminders": [reminder],
                    };

                    try {
                      if (cls.type == 'event') {
                        await repo.createEvent(
                          payload
                            ..["end_time"] = startTime
                                .add(const Duration(hours: 1))
                                .toUtc()
                                .toIso8601String(),
                        );
                        await context.read<CalendarProvider>().loadEvents();
                      } else if (cls.type == 'task') {
                        await repo.createTask(payload..["duration"] = 60);
                        await context.read<TaskProvider>().loadTasks();
                      } else {
                        await repo.createNote(_note);
                        await context.read<NotesProvider>().loadNotes();
                      }
                      TopSnackBar.show(
                        context,
                        message: "Saved successfully!",
                        backgroundColor: Colors.green[700]!,
                      );
                      context.read<SpeechProvider>().resetCardState();
                    } catch (e) {
                      TopSnackBar.show(
                        context,
                        message: "Error: $e",
                        backgroundColor: Colors.red[700]!,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
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
