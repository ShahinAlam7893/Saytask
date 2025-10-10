import 'package:flutter/material.dart';
import '../../model/today_task_model.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  void updateTaskTime(String taskId, DateTime newTime) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.startTime = newTime;
    notifyListeners();
  }
}
