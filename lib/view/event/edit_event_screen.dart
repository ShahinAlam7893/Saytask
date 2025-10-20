import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/calendar_service.dart';
import '../../model/event_model.dart';
import '../../res/color.dart';

class EventEditScreen extends StatelessWidget {
  final Event event;

  const EventEditScreen({super.key, required this.event});

  Future<void> _pickTime(BuildContext context, TextEditingController timeController, CalendarProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: event.time,
    );
    if (picked != null) {
      final updatedEvent = Event(
        id: event.id, // Preserve ID
        title: event.title,
        description: event.description,
        location: event.location,
        date: event.date,
        time: picked,
        reminderMinutes: event.reminderMinutes,
      );
      provider.updateEvent(event, updatedEvent);
      timeController.text = picked.format(context);
    }
  }

  Future<String?> _pickReminder(BuildContext context, CalendarProvider provider) async {
    final availableReminders = [
      '5 min before',
      '10 min before',
      '30 min before',
      '1 hr before',
      '2 hr before',
    ];
    final currentReminders = provider.selectedDayEvents.firstWhere(
          (e) => e.id == event.id, // Use ID
      orElse: () => event,
    ).reminderMinutes;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: Colors.grey, width: 1),
        ),
        title: const Text(
          'Add Reminder',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableReminders.length,
            itemBuilder: (_, i) {
              final reminderMinutes = int.parse(availableReminders[i].split(' ')[0]);
              final isSelected = currentReminders == reminderMinutes;
              return ListTile(
                title: Text(
                  availableReminders[i],
                  style: TextStyle(
                    color: isSelected ? Colors.grey : AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                enabled: !isSelected,
                onTap: () => Navigator.pop(ctx, availableReminders[i]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.black,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    final timeController = TextEditingController(text: event.time.format(context));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          color: AppColors.black,
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () async {
            if (titleController.text != event.title ||
                descriptionController.text != event.description ||
                locationController.text != event.location ||
                timeController.text != event.time.format(context)) {
              final save = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text('Do you want to save changes before leaving?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Discard'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (save == true) {
                final updatedEvent = Event(
                  id: event.id, // Preserve ID
                  title: titleController.text,
                  description: descriptionController.text,
                  location: locationController.text,
                  date: event.date,
                  time: event.time,
                  reminderMinutes: event.reminderMinutes,
                );
                provider.updateEvent(event, updatedEvent);
              }
            }
            context.pop();
          },
        ),
        title: const Text(
          'Edit Event',
          style: TextStyle(
            color: AppColors.black,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Event Title',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(
                    color: AppColors.green,
                    width: 2.0,
                  ),
                ),
              ),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              onChanged: (value) {
                final updatedEvent = Event(
                  id: event.id, // Preserve ID
                  title: value,
                  description: descriptionController.text,
                  location: locationController.text,
                  date: event.date,
                  time: event.time,
                  reminderMinutes: event.reminderMinutes,
                );
                provider.updateEvent(event, updatedEvent);
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: AppColors.green,
                    width: 2.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              cursorColor: AppColors.green,
              style: TextStyle(fontSize: 14.sp),
              onChanged: (value) {
                final updatedEvent = Event(
                  id: event.id, // Preserve ID
                  title: titleController.text,
                  description: value,
                  location: locationController.text,
                  date: event.date,
                  time: event.time,
                  reminderMinutes: event.reminderMinutes,
                );
                provider.updateEvent(event, updatedEvent);
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Location',
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: AppColors.green,
                    width: 2.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              cursorColor: AppColors.green,
              style: TextStyle(fontSize: 14.sp),
              onChanged: (value) {
                final updatedEvent = Event(
                  id: event.id, // Preserve ID
                  title: titleController.text,
                  description: descriptionController.text,
                  location: value,
                  date: event.date,
                  time: event.time,
                  reminderMinutes: event.reminderMinutes,
                );
                provider.updateEvent(event, updatedEvent);
              },
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.green),
                SizedBox(width: 8.w),
                Text(
                  'Schedule',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: DateFormat('MMMM d, yyyy').format(event.date),
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: const BorderSide(
                              color: AppColors.green,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        ),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: () => _pickTime(context, timeController, provider),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: timeController,
                            decoration: InputDecoration(
                              hintText: 'Time',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.r),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.r),
                                borderSide: const BorderSide(
                                  color: AppColors.green,
                                  width: 2.0,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            ),
                            cursorColor: AppColors.green,
                            style: TextStyle(fontSize: 14.sp),
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
                Text(
                  'Reminders',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Consumer<CalendarProvider>(
              builder: (context, provider, _) {
                final currentEvent = provider.selectedDayEvents.firstWhere(
                      (e) => e.id == event.id, // Use ID
                  orElse: () => event,
                );
                final reminders = currentEvent.reminderMinutes != null && currentEvent.reminderMinutes != 0
                    ? ['${currentEvent.reminderMinutes} min before']
                    : [];

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reminders.isEmpty
                        ? [
                      Text(
                        'No reminders set',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                        : reminders.map((reminder) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFBFB),
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                reminder,
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
                                icon: const Icon(Icons.notifications_none, color: AppColors.white),
                                onPressed: () {},
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.wifi_calling_3_outlined, color: AppColors.green),
                              onPressed: () {}, // TODO: Implement call action if needed
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                provider.removeReminderFromEvent(event);
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
            TextButton.icon(
              onPressed: () async {
                final reminder = await _pickReminder(context, provider);
                if (reminder != null) {
                  final minutes = int.parse(reminder.split(' ')[0]);
                  final updatedEvent = Event(
                    id: event.id, // Preserve ID
                    title: titleController.text,
                    description: descriptionController.text,
                    location: locationController.text,
                    date: event.date,
                    time: event.time,
                    reminderMinutes: minutes,
                  );
                  provider.updateEvent(event, updatedEvent);
                }
              },
              icon: const Icon(Icons.add, color: AppColors.black),
              label: Text(
                'Add Reminder',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
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
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Event?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      provider.removeEvent(event);
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete, color: AppColors.red),
                  label: Text(
                    'Delete',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.black),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: AppColors.secondaryTextColor, width: 1.0),
                    padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 8.h),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final updatedEvent = Event(
                      id: event.id, // Preserve ID
                      title: titleController.text,
                      description: descriptionController.text,
                      location: locationController.text,
                      date: event.date,
                      time: event.time,
                      reminderMinutes: event.reminderMinutes,
                    );
                    provider.updateEvent(event, updatedEvent);
                    context.pop();
                  },
                  icon: const Icon(Icons.done, color: AppColors.green),
                  label: Text(
                    'Save',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.black),
                  ),
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