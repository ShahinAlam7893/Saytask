
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytask/model/today_task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  TextEditingController? _titleController;
  TextEditingController? _descriptionController;
  TextEditingController? _startTimeController;
  DateTime? _startTime;

  final Set<String> _selectedCallReminders = {};
  final Set<String> _selectedNotificationReminders = {};

  TextEditingController get titleController => _titleController!;
  TextEditingController get descriptionController => _descriptionController!;
  TextEditingController get startTimeController => _startTimeController!;
  DateTime get startTime => _startTime!;
  Set<String> get selectedCallReminders => _selectedCallReminders;
  Set<String> get selectedNotificationReminders => _selectedNotificationReminders;

  void initializeTaskDetails(Task task) {
    _titleController = TextEditingController(text: task.title);
    _descriptionController = TextEditingController(text: task.description);
    _startTime = task.startTime;
    _startTimeController = TextEditingController(
      text: DateFormat('h:mm a').format(task.startTime),
    );

    _selectedCallReminders.clear();
    _selectedNotificationReminders.clear();

    for (final reminder in task.reminders) {
      final minutes = reminder.timeBefore;
      final label = _minutesToLabel(minutes);
      if (reminder.shouldCall) {
        _selectedCallReminders.add(label);
      } else {
        _selectedNotificationReminders.add(label);
      }
    }

    notifyListeners();
  }

  void disposeTaskDetails() {
    _titleController?.dispose();
    _descriptionController?.dispose();
    _startTimeController?.dispose();

    _titleController = null;
    _descriptionController = null;
    _startTimeController = null;
    _startTime = null;

    _selectedCallReminders.clear();
    _selectedNotificationReminders.clear();

    notifyListeners();
  }

  void updateStartTime(DateTime newStartTime) {
    _startTime = newStartTime;
    _startTimeController?.text = DateFormat('h:mm a').format(newStartTime);
    notifyListeners();
  }

  void toggleCallReminder(String reminder) {
    if (_selectedCallReminders.contains(reminder)) {
      _selectedCallReminders.remove(reminder);
    } else {
      _selectedCallReminders.add(reminder);
    }
    notifyListeners();
  }

  void toggleNotificationReminder(String reminder) {
    if (_selectedNotificationReminders.contains(reminder)) {
      _selectedNotificationReminders.remove(reminder);
    } else {
      _selectedNotificationReminders.add(reminder);
    }
    notifyListeners();
  }
  String _minutesToLabel(int minutes) {
    if (minutes == 5) return "5 minutes before";
    if (minutes == 10) return "10 minutes before";
    if (minutes == 15) return "15 minutes before";
    if (minutes == 30) return "30 minutes before";
    if (minutes == 60) return "1 hour before";
    if (minutes == 120) return "2 hours before";
    return "$minutes minutes before";
  }

  int _labelToMinutes(String label) {
    return int.tryParse(label.split(' ').first) ?? 0;
  }

  void addReminderToTask(String taskId, String reminderLabel) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final minutes = _labelToMinutes(reminderLabel);
    final types = <String>["notification"];
    if (_selectedCallReminders.contains(reminderLabel)) {
      types.add("call");
    }

    final newReminder = TaskReminder(timeBefore: minutes, types: types);
    final updatedReminders = [...task.reminders, newReminder];

    _tasks[taskIndex] = task.copyWith(reminders: updatedReminders);
    notifyListeners();
  }

  void removeReminderFromTask(String taskId, String reminderLabel) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedReminders = task.reminders
        .where((r) => _minutesToLabel(r.timeBefore) != reminderLabel)
        .toList();

    _tasks[taskIndex] = task.copyWith(reminders: updatedReminders);
    _selectedCallReminders.remove(reminderLabel);
    _selectedNotificationReminders.remove(reminderLabel);
    notifyListeners();
  }

  void addTagToTask(String taskId, Tag tag) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedTags = [...task.tags, tag];

    _tasks[taskIndex] = task.copyWith(tags: updatedTags);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void updateTaskTime(String taskId, DateTime newStartTime) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(startTime: newStartTime);
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      notifyListeners();
    }
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }
}