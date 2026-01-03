// lib/view/event/event_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/top_snackbar.dart';

class EventEditScreen extends StatefulWidget {
  final Event event;

  const EventEditScreen({super.key, required this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _selectedDateTime;
  late int _currentReminderMinutes;
  late bool _currentCallMe;

  String _currentTimeText = "Loading...";
  bool _isSaving = false;

  final List<String> _reminderOptions = [
    '5 min before',
    '10 min before',
    '15 min before',
    '30 min before',
    '1 hr before',
    '2 hr before',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _titleController = TextEditingController(text: e.title);
    _descriptionController = TextEditingController(text: e.description);
    _locationController = TextEditingController(text: e.locationAddress);
    _selectedDateTime = e.eventDateTime ?? DateTime.now();
    _currentReminderMinutes = e.reminderMinutes;
    _currentCallMe = e.callMe;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTimeText = TimeOfDay.fromDateTime(_selectedDateTime).format(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
        _currentTimeText = picked.format(context);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<String?> _pickReminder() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: Colors.grey),
        ),
        title: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _reminderOptions.length,
            itemBuilder: (_, i) {
              final text = _reminderOptions[i];
              final minutes = text.contains('hr')
                  ? int.parse(text.split(' ')[0]) * 60
                  : int.parse(text.split(' ')[0]);
              final isSelected = _currentReminderMinutes == minutes;

              return ListTile(
                title: Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.grey : Colors.black,
                  ),
                ),
                enabled: !isSelected,
                onTap: () => Navigator.pop(ctx, text),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  bool _hasChanges() {
    return _titleController.text.trim() != widget.event.title ||
        _descriptionController.text.trim() != widget.event.description ||
        _locationController.text.trim() != widget.event.locationAddress ||
        !_selectedDateTime.isAtSameMomentAs(widget.event.eventDateTime ?? DateTime.now()) ||
        _currentReminderMinutes != widget.event.reminderMinutes ||
        _currentCallMe != widget.event.callMe;
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<CalendarProvider>();
      final updated = widget.event.copyWith(
        title: title,
        description: _descriptionController.text.trim(),
        locationAddress: _locationController.text.trim(),
        eventDateTime: _selectedDateTime,
        reminderMinutes: _currentReminderMinutes,
        callMe: _currentCallMe,
      );

      await provider.updateItem(widget.event, updated);

      if (mounted) {
        TopSnackBar.show(
          context,
          message: "Event updated successfully",
          backgroundColor: Colors.green[700]!,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        TopSnackBar.show(
          context,
          message: "Failed to update: $e",
          backgroundColor: Colors.red[700]!,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Event?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<CalendarProvider>();
      await provider.removeItem(widget.event);

      if (mounted) {
        TopSnackBar.show(
          context,
          message: "Event deleted",
          backgroundColor: Colors.green[700]!,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        TopSnackBar.show(
          context,
          message: "Failed to delete: $e",
          backgroundColor: Colors.red[700]!,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: AppColors.black,
          onPressed: () async {
            if (_hasChanges()) {
              final save = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text('Do you want to save changes before leaving?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Discard')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                  ],
                ),
              );
              if (save == true) {
                await _saveChanges();
                return;
              }
            }
            if (mounted) context.pop();
          },
        ),
        title: const Text('Edit Event', style: TextStyle(color: AppColors.black, fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Event Title',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppColors.green, width: 2.0),
                    ),
                  ),
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),

                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.green, width: 2.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  cursorColor: AppColors.green,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),

                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Location',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.green, width: 2.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  cursorColor: AppColors.green,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.green),
                    SizedBox(width: 8.w),
                    Text('Schedule', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 6.h),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: DateFormat('MMMM d, yyyy').format(_selectedDateTime),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: const BorderSide(color: AppColors.green, width: 2.0),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 6.h),
                          GestureDetector(
                            onTap: _pickTime,
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: _currentTimeText,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                    borderSide: const BorderSide(color: AppColors.green, width: 2.0),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    const Icon(Icons.notifications_none, color: AppColors.green),
                    SizedBox(width: 8.w),
                    Text('Reminders', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  child: _currentReminderMinutes == 0
                      ? Text(
                          'No reminders set',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFBFB),
                            borderRadius: BorderRadius.circular(32.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '$_currentReminderMinutes min before',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF9937),
                                  border: Border.all(color: Colors.grey.shade400, width: 1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.wifi_calling_3_outlined,
                                  color: _currentCallMe ? AppColors.green : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() => _currentCallMe = !_currentCallMe);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _currentReminderMinutes = 0;
                                    _currentCallMe = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                ),
                SizedBox(height: 8.h),

                TextButton.icon(
                  onPressed: () async {
                    final reminder = await _pickReminder();
                    if (reminder != null) {
                      final minutes = reminder.contains('hr')
                          ? int.parse(reminder.split(' ')[0]) * 60
                          : int.parse(reminder.split(' ')[0]);
                      setState(() => _currentReminderMinutes = minutes);
                    }
                  },
                  icon: const Icon(Icons.add, color: AppColors.black),
                  label: Text(
                    'Add Reminder',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.black, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: AppColors.secondaryTextColor, width: 1.0),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                ),
                SizedBox(height: 16.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _isSaving ? null : _deleteEvent,
                      icon: const Icon(Icons.delete, color: AppColors.red),
                      label: Text('Delete', style: TextStyle(fontSize: 14.sp, color: AppColors.black)),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        side: BorderSide(color: AppColors.secondaryTextColor, width: 1.0),
                        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 8.h),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: const Icon(Icons.done, color: AppColors.green),
                      label: Text('Save', style: TextStyle(fontSize: 14.sp, color: AppColors.black)),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        side: BorderSide(color: AppColors.secondaryTextColor, width: 1.0),
                        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 8.h),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}