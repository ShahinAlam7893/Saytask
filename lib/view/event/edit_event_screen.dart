// lib/view/event/event_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/res/color.dart';

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

  String _currentTimeText = "Loading..."; 

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _titleController = TextEditingController(text: e.title);
    _descriptionController = TextEditingController(text: e.description);
    _locationController = TextEditingController(text: e.locationAddress);
    _selectedDateTime = e.eventDateTime ?? DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe: context is ready here
    // ignore: unnecessary_null_comparison
    _currentTimeText = _selectedDateTime != null
        ? TimeOfDay.fromDateTime(_selectedDateTime).format(context)
        : "No time";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(CalendarProvider provider) async {
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
      _updateEvent(provider);
    }
  }

  Future<String?> _pickReminder(CalendarProvider provider) async {
    final options = ['5 min before', '10 min before', '30 min before', '1 hr before', '2 hr before'];
    final currentMinutes = widget.event.reminderMinutes;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: const BorderSide(color: Colors.grey)),
        title: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (_, i) {
              final minutes = int.parse(options[i].split(' ')[0]);
              final isSelected = currentMinutes == minutes;
              return ListTile(
                title: Text(options[i], style: TextStyle(color: isSelected ? Colors.grey : Colors.black)),
                enabled: !isSelected,
                onTap: () => Navigator.pop(ctx, options[i]),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _updateEvent(CalendarProvider provider) {
    final updated = widget.event.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      locationAddress: _locationController.text,
      eventDateTime: _selectedDateTime,
    );
    provider.updateEvent(widget.event, updated);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () async {
            final hasChanges =
                _titleController.text != widget.event.title ||
                _descriptionController.text != widget.event.description ||
                _locationController.text != widget.event.locationAddress ||
                !_selectedDateTime.isAtSameMomentAs(widget.event.eventDateTime ?? DateTime.now());

            if (hasChanges) {
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
              if (save == true) _updateEvent(provider);
            }
            if (mounted) context.pop();
          },
        ),
        title: const Text('Edit Event', style: TextStyle(color: AppColors.black, fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Event Title',
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: AppColors.green, width: 2.0)),
              ),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              onChanged: (_) => _updateEvent(provider),
            ),
            SizedBox(height: 16.h),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColors.green, width: 2.0)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              cursorColor: AppColors.green,
              style: TextStyle(fontSize: 14.sp),
              onChanged: (_) => _updateEvent(provider),
            ),
            SizedBox(height: 16.h),

            // Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Location',
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColors.green, width: 2.0)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              cursorColor: AppColors.green,
              style: TextStyle(fontSize: 14.sp),
              onChanged: (_) => _updateEvent(provider),
            ),
            SizedBox(height: 16.h),

            // Schedule
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
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: DateFormat('MMMM d, yyyy').format(_selectedDateTime),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: AppColors.green, width: 2.0)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                        onTap: () => _pickTime(provider),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: _currentTimeText,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: AppColors.green, width: 2.0)),
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

            // Reminders
            Row(
              children: [
                const Icon(Icons.notifications_none, color: AppColors.green),
                SizedBox(width: 8.w),
                Text('Reminders', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8.h),
            Consumer<CalendarProvider>(
              builder: (context, provider, _) {
                final currentEvent = provider.getEventsForDate(_selectedDateTime).firstWhere(
                  (e) => e.id == widget.event.id,
                  orElse: () => widget.event,
                );

                final reminders = currentEvent.reminderMinutes > 0
                    ? ['${currentEvent.reminderMinutes} min before']
                    : <String>[];

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  child: reminders.isEmpty
                      ? Text('No reminders set', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontStyle: FontStyle.italic))
                      : Column(
                          children: reminders.map((r) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
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
                                    child: Text(r, style: TextStyle(fontSize: 14.sp, color: AppColors.black, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF9937),
                                      border: Border.all(color: Colors.grey.shade400, width: 1),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_none, color: AppColors.white),
                                      onPressed: () {},
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.wifi_calling_3_outlined, color: AppColors.green),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      final cleared = currentEvent.copyWith(reminderMinutes: 0, callMe: false);
                                      provider.updateEvent(currentEvent, cleared);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                );
              },
            ),
            SizedBox(height: 8.h),

            // Add Reminder
            TextButton.icon(
              onPressed: () async {
                final reminder = await _pickReminder(provider);
                if (reminder != null) {
                  final minutes = int.parse(reminder.split(' ')[0]);
                  final updated = widget.event.copyWith(reminderMinutes: minutes);
                  provider.updateEvent(widget.event, updated);
                }
              },
              icon: const Icon(Icons.add, color: AppColors.black),
              label: Text('Add Reminder', style: TextStyle(fontSize: 14.sp, color: AppColors.black, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.white,
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.secondaryTextColor, width: 1.0),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
            ),
            SizedBox(height: 16.h),

            // Delete & Save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Event?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      provider.removeEvent(widget.event);
                      if (mounted) context.pop();
                    }
                  },
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
                  onPressed: () {
                    _updateEvent(provider);
                    context.pop();
                  },
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
    );
  }
}