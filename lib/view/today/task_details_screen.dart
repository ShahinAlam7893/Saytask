// lib/view/task/task_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/res/color.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Task? _task;
  bool _isLoading = true;
  String? _errorMessage;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTask();
    });
  }

  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.loadTasks();

      final foundTask = taskProvider.tasks.cast<Task?>().firstWhere(
        (t) => t?.id == widget.taskId,
        orElse: () => null,
      );

      if (foundTask == null) {
        setState(() {
          _errorMessage = "Task not found. It may have been deleted.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _task = foundTask;
        _initializeControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load task. Please try again.";
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: _task!.title);
    _descriptionController = TextEditingController(text: _task!.description);
    _startTime = _task!.startTime;

    _startTimeController = TextEditingController(
      text: DateFormat('h:mm a').format(_startTime),
    );

    _endTimeController = TextEditingController(
      text: _task!.endTime != null
          ? DateFormat('h:mm a').format(_task!.endTime!)
          : DateFormat('h:mm a').format(_startTime.add(_task!.duration)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          picked.hour,
          picked.minute,
        );
        _startTimeController.text = picked.format(context);
        _endTimeController.text = DateFormat('h:mm a').format(_startTime.add(_task!.duration));
      });
    }
  }

  Future<Tag?> _pickTag(BuildContext context) async {
    final availableTags = [
      Tag(name: 'Work', backgroundColor: const Color(0xFFEDE7F6), textColor: const Color(0xFF7E57C2)),
      Tag(name: 'Personal', backgroundColor: const Color(0xFFFFF1E0), textColor: const Color(0xFFF9A825)),
      Tag(name: 'Shopping', backgroundColor: const Color(0xFFFFF1E0), textColor: const Color(0xFFF9A825)),
      Tag(name: 'Urgent', backgroundColor: const Color(0xFFFFEBEE), textColor: const Color(0xFFD32F2F)),
      Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
    ];

    return showDialog<Tag>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: const BorderSide(color: Colors.grey)),
        title: const Text('Choose a Tag', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableTags.length,
            itemBuilder: (_, i) => ListTile(
              leading: CircleAvatar(backgroundColor: availableTags[i].backgroundColor),
              title: Text(availableTags[i].name, style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, availableTags[i]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<String?> _pickReminder(BuildContext context) async {
    final availableReminders = [
      '5 min before',
      '10 min before',
      '30 min before',
      '1 hr before',
      '2 hr before',
    ];

    final currentLabels = _task!.reminders.map((r) => _minutesToLabel(r.timeBefore)).toSet();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: const BorderSide(color: Colors.grey)),
        title: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableReminders.length,
            itemBuilder: (_, i) {
              final isSelected = currentLabels.contains(availableReminders[i]);
              return ListTile(
                title: Text(availableReminders[i], style: TextStyle(color: isSelected ? Colors.grey : Colors.black, fontWeight: FontWeight.w500)),
                enabled: !isSelected,
                onTap: () => Navigator.pop(ctx, availableReminders[i]),
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

  String _minutesToLabel(int minutes) {
    if (minutes == 5) return "5 min before";
    if (minutes == 10) return "10 min before";
    if (minutes == 30) return "30 min before";
    if (minutes == 60) return "1 hr before";
    if (minutes == 120) return "2 hr before";
    return "$minutes min before";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _task == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Task Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                _errorMessage ?? "Task not found",
                style: TextStyle(fontSize: 18.sp, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _loadTask,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () async {
            final hasChanges =
                _titleController.text != _task!.title ||
                _descriptionController.text != _task!.description ||
                !_startTime.isAtSameMomentAs(_task!.startTime);

            if (hasChanges) {
              final save = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text('Save changes before leaving?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Discard')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                  ],
                ),
              );

              if (save == true) {
                final updatedTask = _task!.copyWith(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  startTime: _startTime,
                );
                context.read<TaskProvider>().updateTask(updatedTask);
              }
            }
            if (mounted) context.pop();
          },
        ),
        title: const Text('Task Details', style: TextStyle(color: AppColors.black, fontFamily: 'Poppins')),
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
                hintText: 'Task',
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
              ),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
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
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              cursorColor: Colors.green,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),

            // Schedule
            Row(children: [const Icon(Icons.schedule, color: Colors.green), SizedBox(width: 8.w), Text('Schedule', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold))]),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Time', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: () => _pickStartTime(context),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _startTimeController,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
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
                      Text('End Time', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _endTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Tags (read-only display)
            Row(children: [const Icon(Icons.local_offer, color: Colors.green), SizedBox(width: 8.w), Text('Tags', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold))]),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _task!.tags.map((tag) => Chip(
                label: Text(tag.name, style: TextStyle(fontSize: 12.sp, color: tag.textColor)),
                backgroundColor: tag.backgroundColor,
                shape: const StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              )).toList(),
            ),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: () async {
                final tag = await _pickTag(context);
                if (tag != null) {
                  context.read<TaskProvider>().addTagToTask(_task!.id, tag);
                }
              },
              icon: const Icon(Icons.add, color: AppColors.black),
              label: Text('Add Tag', style: TextStyle(fontSize: 14.sp, color: AppColors.black, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(shape: const StadiumBorder(), side: BorderSide(color: AppColors.secondaryTextColor, width: 1)),
            ),
            SizedBox(height: 16.h),

            // Reminders
            Row(children: [const Icon(Icons.notifications_none, color: Colors.green), SizedBox(width: 8.w), Text('Reminders', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold))]),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              child: _task!.reminders.isEmpty
                  ? Text('No reminders set', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontStyle: FontStyle.italic))
                  : Column(
                      children: _task!.reminders.map((r) {
                        final label = _minutesToLabel(r.timeBefore);
                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(color: const Color(0xFFFBFBFB), borderRadius: BorderRadius.circular(32.r), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            children: [
                              SizedBox(width: 8.w),
                              Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp, color: AppColors.black, fontWeight: FontWeight.w600))),
                              Container(
                                decoration: BoxDecoration(color: const Color(0xFFEF9937), borderRadius: BorderRadius.circular(12.r)),
                                child: IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
                              ),
                              if (r.shouldCall) IconButton(icon: const Icon(Icons.wifi_calling_3_outlined, color: AppColors.green), onPressed: () {}),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => context.read<TaskProvider>().removeReminderFromTask(_task!.id, label),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: () async {
                final reminder = await _pickReminder(context);
                if (reminder != null) {
                  context.read<TaskProvider>().addReminderToTask(_task!.id, reminder);
                }
              },
              icon: const Icon(Icons.add, color: AppColors.black),
              label: Text('Add Reminder', style: TextStyle(fontSize: 14.sp, color: AppColors.black, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(shape: const StadiumBorder(), side: BorderSide(color: AppColors.secondaryTextColor, width: 1)),
            ),
            SizedBox(height: 16.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text('Delete Task?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.black))),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.red))),
                      ],
                    ));
                    if (confirm == true) {
                      context.read<TaskProvider>().removeTask(_task!.id);
                      if (mounted) context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete, color: AppColors.red),
                  label: Text('Delete', style: TextStyle(fontSize: 14.sp, color: AppColors.black)),
                  style: TextButton.styleFrom(shape: const StadiumBorder(), side: BorderSide(color: AppColors.secondaryTextColor, width: 1), padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 8.h)),
                ),
                TextButton.icon(
                  onPressed: () {
                    final updatedTask = _task!.copyWith(
                      title: _titleController.text.trim(),
                      description: _descriptionController.text.trim(),
                      startTime: _startTime,
                    );
                    context.read<TaskProvider>().updateTask(updatedTask);
                    context.pop();
                  },
                  icon: const Icon(Icons.done, color: AppColors.green),
                  label: Text('Save', style: TextStyle(fontSize: 14.sp, color: AppColors.black)),
                  style: TextButton.styleFrom(shape: const StadiumBorder(), side: BorderSide(color: AppColors.secondaryTextColor, width: 1), padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 8.h)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}