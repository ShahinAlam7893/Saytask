import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/color.dart';
import '../../model/today_task_model.dart';
import '../../repository/today_task_service.dart';
import '../../res/components/schedule_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _scheduleScrollController = ScrollController();
  final ScrollController _timelineScrollController = ScrollController();
  final double _hourHeight = 120.h;
  final int _defaultStartHour = 6;
  final int _defaultEndHour = 23;

  // View mode toggle
  bool _isCompactView = false;

  Task? _draggedTask;
  bool _autoScrolling = false;

  // Auto-scroll settings
  final double _scrollThreshold = 80;
  final double _scrollSpeed = 10;

  Offset? _pointerOffset;

  @override
  void initState() {
    super.initState();

    _scheduleScrollController.addListener(() {
      _timelineScrollController.jumpTo(_scheduleScrollController.offset);
    });
    _timelineScrollController.addListener(() {
      _scheduleScrollController.jumpTo(_timelineScrollController.offset);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.setTasks(_initializeTasks());
      _startAutoCompletionTimer();
    });
  }

  void _startAutoCompletionTimer() {
    // Check every minute for tasks that should be auto-completed
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        for (var task in taskProvider.tasks) {
          if (task.shouldBeCompleted() && !task.isCompleted) {
            taskProvider.toggleTaskCompletion(task.id);
          }
        }
        _startAutoCompletionTimer();
      }
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _scheduleScrollController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  List<Task> _initializeTasks() {
    final today = DateTime(2025, 10, 1);
    return [
      Task(
        id: '1',
        title: 'Buy groceries',
        description: '',
        startTime: today.add(const Duration(hours: 7)),
        duration: const Duration(hours: 1, minutes: 30),
        tags: [
          Tag(
              name: 'Shopping',
              backgroundColor: const Color(0xFFFFF1E0),
              textColor: const Color(0xFFF9A825)),
          Tag(
              name: 'Important',
              backgroundColor: const Color(0xFFE3F2FD),
              textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '2',
        title: 'Office Meeting',
        description: 'This is our monthly report meeting',
        startTime: today.add(const Duration(hours: 9)),
        duration: const Duration(hours: 1),
        tags: [
          Tag(
              name: 'Work',
              backgroundColor: const Color(0xFFEDE7F6),
              textColor: const Color(0xFF7E57C2)),
          Tag(
              name: 'Important',
              backgroundColor: const Color(0xFFE3F2FD),
              textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'Client Meeting',
        description: '',
        startTime: today.add(const Duration(hours: 11)),
        duration: const Duration(minutes: 45),
        tags: [
          Tag(
              name: 'Work',
              backgroundColor: const Color(0xFFFCE4EC),
              textColor: const Color(0xFFEC407A)),
          Tag(
              name: 'Important',
              backgroundColor: const Color(0xFFE3F2FD),
              textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '4',
        title: 'Morning coffee with client',
        description: '',
        startTime: today.add(const Duration(hours: 10)),
        duration: const Duration(minutes: 45),
        tags: [
          Tag(
              name: 'Work',
              backgroundColor: const Color(0xFFEDE7F6),
              textColor: const Color(0xFF7E57C2)),
          Tag(
              name: 'Important',
              backgroundColor: const Color(0xFFE3F2FD),
              textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '5',
        title: 'Team-meeting preparation',
        description: '',
        startTime: today.add(const Duration(hours: 12)),
        duration: const Duration(minutes: 45),
        tags: [
          Tag(
              name: 'Work',
              backgroundColor: const Color(0xFFEDE7F6),
              textColor: const Color(0xFF7E57C2)),
          Tag(
              name: 'Important',
              backgroundColor: const Color(0xFFE3F2FD),
              textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        if (_isCompactView) {
          return _buildCompactView(taskProvider);
        } else {
          return _buildExpandedView(taskProvider);
        }
      },
    );
  }

  Widget _buildCompactView(TaskProvider taskProvider) {
    // Sort tasks by start time
    final sortedTasks = List<Task>.from(taskProvider.tasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                controller: _mainScrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: sortedTasks.length,
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time label
                        SizedBox(
                          width: 40.w,
                          child: Text(
                            DateFormat('h a').format(task.startTime),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        // Green bubble
                        Column(
                          children: [
                            SizedBox(height: 6.h),
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? Colors.grey[400]
                                    : const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        // Task card
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('/task-details', extra: task);
                            },
                            child: _buildCompactTaskCard(task),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTaskCard(Task task) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white, // always white, ignore completion
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color:
                    task.isCompleted ? Colors.grey[600] : Colors.black87,
                    fontFamily: 'Poppins',
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: task.tags
                      .map((tag) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: tag.backgroundColor, // always tag color
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        color: tag.textColor, // always tag color
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ))
                      .toList(),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Text(
                      _formatDuration(task.duration),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Checkbox for completion
          GestureDetector(
            onTap: () {
              Provider.of<TaskProvider>(context, listen: false)
                  .toggleTaskCompletion(task.id);
            },
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? Colors.grey[400]! : const Color(0xFF4CAF50),
                  width: 2.0,
                ),
                color: task.isCompleted ? Colors.grey[400] : Colors.transparent,
              ),
              child: task.isCompleted
                  ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                  : null,
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }


  Widget _buildExpandedView(TaskProvider taskProvider) {
    // Determine timeline range based on tasks
    int startHour = _defaultStartHour;
    int endHour = _defaultEndHour;
    for (var task in taskProvider.tasks) {
      final taskHour = task.startTime.hour;
      if (taskHour < startHour) startHour = 1;
      if (taskHour >= endHour) endHour = 24;
    }
    startHour = startHour < _defaultStartHour ? 1 : _defaultStartHour;
    endHour = endHour > _defaultEndHour ? 24 : _defaultEndHour;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _mainScrollController,
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(
                height: (endHour - startHour + 1) * _hourHeight + 20.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeline(startHour, endHour),
                    _buildScrollableDivider(startHour, endHour),
                    Expanded(child: _buildScheduleArea(startHour, endHour)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('EEEE, MMMM d, y').format(now);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                'assets/images/Saytask_logo.svg',
                height: 24.h,
                width: 100.w,
              ),
              Icon(Icons.settings_outlined,
                  size: 24.sp, color: AppColors.black),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Today',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCompactView = !_isCompactView;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isCompactView ? 'Expanded Schedule' : 'Compact View',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Icon(
                  _isCompactView

                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.grey[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int startHour, int endHour) {
    return SizedBox(
      width: 60.w,
      child: SingleChildScrollView(
        controller: _timelineScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(endHour - startHour + 1, (index) {
            final hour = startHour + index;
            return SizedBox(
              height: _hourHeight,
              child: Text(
                DateFormat('h a').format(DateTime(2025, 1, 1, hour)),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScrollableDivider(int startHour, int endHour) {
    return Container(
      width: 1.w,
      color: Colors.grey[300],
      margin: EdgeInsets.only(top: 1.h),
      child: SingleChildScrollView(
        controller: _timelineScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(
            endHour - startHour + 1,
                (index) => Container(
              height: _hourHeight,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleArea(int startHour, int endHour) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return Listener(
          onPointerMove: (event) {
            _pointerOffset = event.localPosition;
          },
          child: DragTarget<Task>(
            onWillAccept: (_) => true,
            onAcceptWithDetails: (details) {
              final renderBox = context.findRenderObject() as RenderBox;
              final localOffset = renderBox.globalToLocal(details.offset);

              final dy = localOffset.dy + _scheduleScrollController.offset;

              final totalMinutes = (dy / _hourHeight) * 60;
              final snappedMinutes = (totalMinutes / 15).round() * 15;
              final newHour = (snappedMinutes / 60).floor() + startHour;
              final newMinute = snappedMinutes % 60;

              final task = details.data;
              final oldTime = task.startTime;

              final newStartTime = DateTime(
                oldTime.year,
                oldTime.month,
                oldTime.day,
                newHour,
                newMinute,
              );

              taskProvider.updateTaskTime(task.id, newStartTime);

              // Auto-reactivate if dragged to future time
              final now = DateTime.now();
              final newEndTime = newStartTime.add(task.duration);
              if (task.isCompleted && now.isBefore(newEndTime)) {
                taskProvider.toggleTaskCompletion(task.id);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return SingleChildScrollView(
                controller: _scheduleScrollController,
                child: SizedBox(
                  height: (endHour - startHour + 1) * _hourHeight,
                  child: Stack(
                    children: [
                      _buildTimeSlotLines(startHour, endHour),
                      ...taskProvider.tasks.map((task) {
                        final minutesFromStart =
                            task.startTime.hour * 60 + task.startTime.minute;
                        final startHourMinutes = startHour * 60;
                        final topPosition =
                            ((minutesFromStart - startHourMinutes) / 60.0) *
                                _hourHeight;

                        return Positioned(
                          top: topPosition,
                          left: 0,
                          right: 16.w,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Green bubble aligned with divider
                              Positioned(
                                left: -6.w,
                                top: 0,
                                child: Container(
                                  width: 10.w,
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    color: task.isCompleted
                                        ? Colors.grey[400]
                                        : const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Draggable schedule card
                              LongPressDraggable<Task>(
                                data: task,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          100.w,
                                      child: ScheduleCard(
                                          task: task, hourHeight: _hourHeight),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: ScheduleCard(
                                      task: task, hourHeight: _hourHeight),
                                ),
                                onDragStarted: () {
                                  _draggedTask = task;
                                  _startAutoScroll();
                                },
                                onDragEnd: (_) {
                                  _draggedTask = null;
                                  _stopAutoScroll();
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    context.push('/task-details', extra: task);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 5.w),
                                    child: _buildExpandedTaskCard(task),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpandedTaskCard(Task task) {
    return ClipRect(
      child: Container(
        height: _hourHeight,
        padding: EdgeInsets.all(8.w),
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: Colors.white, // always white
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('h:mm a').format(task.startTime),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700], // always green
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color:
                      task.isCompleted ? Colors.grey[600] : Colors.black87,
                      fontFamily: 'Poppins',
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: task.tags
                        .map((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: tag.backgroundColor, // always tag color
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          color: tag.textColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.notifications_none_outlined, size: 12.sp, color: Colors.grey[600]),
                      SizedBox(width: 2.w),
                      Text(
                        _formatDuration(task.duration),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Provider.of<TaskProvider>(context, listen: false)
                    .toggleTaskCompletion(task.id);
              },
              child: Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted ? Colors.grey[400]! : const Color(0xFF4CAF50),
                    width: 2.0,
                  ),
                  color: task.isCompleted ? Colors.grey[400] : Colors.transparent,
                ),
                child: task.isCompleted
                    ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return "${hours} hr, ${minutes} min";
    } else {
      return "${minutes} min";
    }
  }

  Widget _buildTimeSlotLines(int startHour, int endHour) {
    return Column(
      children: List.generate(
        endHour - startHour + 1,
            (index) => Container(
          height: _hourHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 1.0),
            ),
          ),
        ),
      ),
    );
  }

  void _startAutoScroll() async {
    _autoScrolling = true;

    while (_autoScrolling && _draggedTask != null) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted || _pointerOffset == null) return;

      final pointerY = _pointerOffset!.dy;
      final maxScroll = _scheduleScrollController.position.maxScrollExtent;
      final currentScroll = _scheduleScrollController.offset;

      double scrollDelta = 0;

      if (pointerY < _scrollThreshold) {
        scrollDelta = -_scrollSpeed * (1 - pointerY / _scrollThreshold);
      } else if (pointerY >
          MediaQuery.of(context).size.height - _scrollThreshold) {
        final distance =
            pointerY - (MediaQuery.of(context).size.height - _scrollThreshold);
        scrollDelta = _scrollSpeed * (1 + distance / _scrollThreshold);
      }

      final newOffset = (currentScroll + scrollDelta).clamp(0.0, maxScroll);

      _scheduleScrollController.jumpTo(newOffset);
      _timelineScrollController.jumpTo(newOffset);
    }
  }

  void _stopAutoScroll() {
    _autoScrolling = false;
  }
}