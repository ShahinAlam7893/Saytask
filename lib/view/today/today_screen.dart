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
  final double _hourHeight = 100.h; // Reduced from 200.h for compact timeline
  final int _defaultStartHour = 6;
  final int _defaultEndHour = 23;

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
        reminders: [], // Explicitly set mutable list
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
        reminders: [], // Explicitly set mutable list
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
        reminders: [], // Explicitly set mutable list
      ),

      Task(
        id: '4',
        title: 'Early Morning Task',
        description: '',
        startTime: today.add(const Duration(hours: 3)),
        duration: const Duration(minutes: 30),
        tags: [
          Tag(
              name: 'Personal',
              backgroundColor: const Color(0xFFE8F5E9),
              textColor: const Color(0xFF4CAF50)),
        ],
        reminders: [],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
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
      },
    );
  }

  Widget _buildHeader() {
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
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Today',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6.h),
          Text(
            'Wednesday, October 1, 2025',
            style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Compact View',
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500),
              ),
              Icon(Icons.keyboard_arrow_up, color: Colors.grey[700]),
            ],
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
                    fontWeight: FontWeight.w700),
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

              taskProvider.updateTaskTime(
                task.id,
                DateTime(
                  oldTime.year,
                  oldTime.month,
                  oldTime.day,
                  newHour,
                  newMinute,
                ),
              );
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
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
                                    child: ScheduleCard(
                                        task: task, hourHeight: _hourHeight),
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
                                    child: ScheduleCard(
                                        task: task, hourHeight: _hourHeight),
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

      // Scroll up if near top
      if (pointerY < _scrollThreshold) {
        scrollDelta = -_scrollSpeed * (1 - pointerY / _scrollThreshold);
      }
      // Scroll down if near bottom
      else if (pointerY > MediaQuery.of(context).size.height - _scrollThreshold) {
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
