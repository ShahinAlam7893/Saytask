import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytask/model/today_task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  // Temporary state for TaskDetailsScreen
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
    _startTimeController = TextEditingController(
      text: DateFormat('h:mm a').format(task.startTime),
    );
    _startTime = task.startTime;
    _selectedCallReminders.clear();
    _selectedNotificationReminders.clear();
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
      print('Call button for "$reminder" deselected');
    } else {
      _selectedCallReminders.add(reminder);
      print('Call button for "$reminder" selected');
    }
    notifyListeners();
  }

  void toggleNotificationReminder(String reminder) {
    if (_selectedNotificationReminders.contains(reminder)) {
      _selectedNotificationReminders.remove(reminder);
      print('Notification button for "$reminder" deselected');
    } else {
      _selectedNotificationReminders.add(reminder);
      print('Notification button for "$reminder" selected');
    }
    notifyListeners();
  }

  void removeReminderFromTask(String taskId, String reminder) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedReminders = List<String>.from(task.reminders ?? [])..remove(reminder);
      _tasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        startTime: task.startTime,
        duration: task.duration,
        tags: task.tags,
        reminders: updatedReminders,
        isCompleted: task.isCompleted,
      );
      _selectedCallReminders.remove(reminder);
      _selectedNotificationReminders.remove(reminder);
      print('Removed reminder "$reminder" from task $taskId. New reminders: $updatedReminders');
      notifyListeners();
    }
  }

  void addReminderToTask(String taskId, String reminder) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedReminders = List<String>.from(task.reminders ?? [])..add(reminder);
      _tasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        startTime: task.startTime,
        duration: task.duration,
        tags: task.tags,
        reminders: updatedReminders,
        isCompleted: task.isCompleted,
      );
      print('Added reminder "$reminder" to task $taskId. New reminders: $updatedReminders');
      notifyListeners();
    }
  }

  void addTagToTask(String taskId, Tag tag) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTags = List<Tag>.from(task.tags)..add(tag);
      _tasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        startTime: task.startTime,
        duration: task.duration,
        tags: updatedTags,
        reminders: task.reminders ?? [],
        isCompleted: task.isCompleted,
      );
      notifyListeners();
    }
  }


  void updateTask(Task updatedTask) {
    final taskIndex = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (taskIndex != -1) {
      _tasks[taskIndex] = updatedTask;
      notifyListeners();
    }
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void updateTaskTime(String taskId, DateTime newStartTime) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      _tasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        startTime: newStartTime,
        duration: task.duration,
        tags: task.tags,
        reminders: task.reminders ?? [],
        isCompleted: task.isCompleted,
      );
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      _tasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        startTime: task.startTime,
        duration: task.duration,
        tags: task.tags,
        reminders: task.reminders ?? [],
        isCompleted: !task.isCompleted,
      );
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