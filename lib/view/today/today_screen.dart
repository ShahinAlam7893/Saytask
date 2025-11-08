import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/color.dart';
import '../../model/today_task_model.dart';
import '../../repository/today_task_service.dart';
import 'dart:async';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _scheduleScrollController = ScrollController();
  final ScrollController _timelineScrollController = ScrollController();

  // ────── Layout constants ──────
  static const double _cardHeight = 120.0;
  static const double _cardGap = 5.0;
  static const double _emptyHourHeight = 120.0;

  static const int _defaultStartHour = 6;
  static const int _defaultEndHour = 23;

  bool _isCompactView = false;

  Task? _draggedTask;
  bool _autoScrolling = false;
  static const _scrollThreshold = 80.0;
  static const _scrollSpeed = 10.0;
  Offset? _pointerOffset;
  final GlobalKey _scheduleAreaKey = GlobalKey();

  Timer? _autoCompletionTimer;

  // Drag preview
  String? _previewTime;
  double? _previewTop;

  // ──────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _syncScrollControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = Provider.of<TaskProvider>(context, listen: false);
      final tasks = _initializeTasks();
      tp.setTasks(tasks);

      // Auto-check past tasks on load
      _autoCheckPastTasks(tasks);
    });
  }

  void _autoCheckPastTasks(List<Task> tasks) {
    final now = DateTime.now();
    for (final task in tasks) {
      final endTime = task.startTime.add(task.duration);
      if (endTime.isBefore(now) && !task.isCompleted) {
        Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(task.id);
      }
    }
  }

  void _syncScrollControllers() {
    _scheduleScrollController.addListener(() {
      if (_timelineScrollController.offset != _scheduleScrollController.offset) {
        _timelineScrollController.jumpTo(_scheduleScrollController.offset);
      }
    });
    _timelineScrollController.addListener(() {
      if (_scheduleScrollController.offset != _timelineScrollController.offset) {
        _scheduleScrollController.jumpTo(_timelineScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _autoCompletionTimer?.cancel();
    _mainScrollController.dispose();
    _scheduleScrollController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // SAMPLE DATA
  // ──────────────────────────────────────────────────────────────
  List<Task> _initializeTasks() {
    final today = DateTime.now();
    return [
      Task(
        id: '1',
        title: 'Team-meeting preparation',
        description: '',
        startTime: DateTime(today.year, today.month, today.day, 8, 0),
        duration: const Duration(hours: 1),
        tags: [
          Tag(name: 'Work', backgroundColor: const Color(0xFFEDE7F6), textColor: const Color(0xFF7E57C2)),
          Tag(name: 'Urgent', backgroundColor: const Color(0xFFFFEBEE), textColor: const Color(0xFFD32F2F)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '2',
        title: 'Buy groceries',
        description: '',
        startTime: DateTime(today.year, today.month, today.day, 9, 0),
        duration: const Duration(hours: 1, minutes: 30),
        tags: [
          Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
          Tag(name: 'Shopping', backgroundColor: const Color(0xFFFFF1E0), textColor: const Color(0xFFF9A825)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'Morning coffee with client',
        description: '',
        startTime: DateTime(today.year, today.month, today.day, 9, 30),
        duration: const Duration(minutes: 45),
        tags: [
          Tag(name: 'Work', backgroundColor: const Color(0xFFFCE4EC), textColor: const Color(0xFFEC407A)),
          Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '4',
        title: 'Quick phone check-in',
        description: '',
        startTime: DateTime(today.year, today.month, today.day, 9, 45),
        duration: const Duration(minutes: 5),
        tags: [
          Tag(name: 'Work', backgroundColor: const Color(0xFFE8F5E9), textColor: const Color(0xFF43A047)),
        ],
        reminders: [],
        isCompleted: false,
      ),
      Task(
        id: '5',
        title: 'Client Meeting',
        description: '',
        startTime: DateTime(today.year, today.month, today.day, 11, 0),
        duration: const Duration(minutes: 45),
        tags: [
          Tag(name: 'Work', backgroundColor: const Color(0xFFFCE4EC), textColor: const Color(0xFFEC407A)),
          Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
        ],
        reminders: [],
        isCompleted: false,
      ),
    ];
  }

  // ──────────────────────────────────────────────────────────────
  // UI STATE HELPERS
  // ──────────────────────────────────────────────────────────────
  bool _isFaded(Task t) => t.isCompleted;
  bool _hasStrikethrough(Task t) => t.isCompleted;

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, tp, _) => _isCompactView
          ? _buildCompactView(tp)
          : _buildExpandedView(tp),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // COMPACT VIEW
  // ──────────────────────────────────────────────────────────────
  Widget _buildCompactView(TaskProvider tp) {
    final sorted = List<Task>.from(tp.tasks)
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
                itemCount: sorted.length,
                itemBuilder: (_, i) => _buildCompactTaskItem(sorted[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTaskItem(Task t) {
    final isFaded = _isFaded(t);
    final hasStrikethrough = _hasStrikethrough(t);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.w,
            child: Text(
              DateFormat('h a').format(t.startTime),
              style: TextStyle(fontSize: 12.sp, color: AppColors.black, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 6.h),
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: t.isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/task-details', extra: t),
              child: _buildCompactCard(t, isFaded, hasStrikethrough),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(Task t, bool faded, bool strikethrough) {
    return Opacity(
      opacity: faded ? 0.4 : 1.0,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: t.isCompleted ? Colors.grey[600] : Colors.black87,
                      fontFamily: 'Poppins',
                      decoration: strikethrough ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: t.tags
                        .map((tg) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: tg.backgroundColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        tg.name,
                        style: TextStyle(
                            color: tg.textColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins'),
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
                        _formatDuration(t.duration),
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCheckbox(
              isChecked: t.isCompleted,
              onTap: () => Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(t.id),
              size: 30.w,
              iconSize: 26.sp,
            ),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // EXPANDED VIEW
  // ──────────────────────────────────────────────────────────────
  Widget _buildExpandedView(TaskProvider tp) {
    const int startHour = _defaultStartHour;
    const int endHour = _defaultEndHour;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _mainScrollController,
          child: Column(
            children: [
              _buildHeader(),
              Consumer<TaskProvider>(
                builder: (context, tp, _) {
                  final allTasks = List<Task>.from(tp.tasks)
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  final layout = _computeTimelineLayout(allTasks, startHour, endHour);
                  final hourHeightMap = layout['hourHeightMap'] as Map<int, double>;
                  final minuteToOffset = layout['minuteToOffset'] as Map<int, double>;
                  final totalHeight = layout['totalHeight'] as double;

                  return SizedBox(
                    height: totalHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDynamicTimeline(startHour, endHour, hourHeightMap),
                        _buildScrollableDivider(startHour, endHour, hourHeightMap),
                        Expanded(
                          child: _buildScheduleArea(
                            startHour: startHour,
                            endHour: endHour,
                            allTasks: allTasks,
                            hourHeightMap: hourHeightMap,
                            minuteToOffset: minuteToOffset,
                            totalHeight: totalHeight,
                            taskProvider: tp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────── LAYOUT CALCULATION ──────────────────────
  Map<String, dynamic> _computeTimelineLayout(
      List<Task> tasks, int startHour, int endHour) {
    final hourTaskCount = <int, int>{};
    for (final t in tasks) {
      final h = t.startTime.hour;
      if (h >= startHour && h <= endHour) {
        hourTaskCount[h] = (hourTaskCount[h] ?? 0) + 1;
      }
    }

    final hourHeightMap = <int, double>{};
    for (int h = startHour; h <= endHour; h++) {
      final cnt = hourTaskCount[h] ?? 0;
      hourHeightMap[h] = cnt > 0
          ? cnt * (_cardHeight + _cardGap)
          : _emptyHourHeight;
    }

    final minuteToOffset = <int, double>{};
    double cumulative = 0.0;
    for (int h = startHour; h <= endHour; h++) {
      final hh = hourHeightMap[h]!;
      final ppm = hh / 60.0;
      for (int m = 0; m < 60; m++) {
        minuteToOffset[h * 60 + m] = cumulative + m * ppm;
      }
      cumulative += hh;
    }

    return {
      'hourHeightMap': hourHeightMap,
      'minuteToOffset': minuteToOffset,
      'totalHeight': cumulative + 20.h,
    };
  }

  // ────────────────────── TIMELINE & DIVIDER ──────────────────────
  Widget _buildDynamicTimeline(int startHour, int endHour, Map<int, double> hourHeightMap) {
    return SizedBox(
      width: 60.w,
      child: SingleChildScrollView(
        controller: _timelineScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(endHour - startHour + 1, (i) {
            final hour = startHour + i;
            return SizedBox(
              height: hourHeightMap[hour],
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    DateFormat('h a').format(DateTime(2025, 1, 1, hour)),
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScrollableDivider(int startHour, int endHour, Map<int, double> hourHeightMap) {
    return Container(
      width: 1.w,
      color: Colors.grey[300],
      margin: EdgeInsets.only(top: 1.h),
      child: SingleChildScrollView(
        controller: _timelineScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(endHour - startHour + 1, (i) {
            final height = hourHeightMap[startHour + i]!;
            return Container(height: height, color: Colors.grey[300]);
          }),
        ),
      ),
    );
  }

  // ────────────────────── SCHEDULE AREA ──────────────────────
  Widget _buildScheduleArea({
    required int startHour,
    required int endHour,
    required List<Task> allTasks,
    required Map<int, double> hourHeightMap,
    required Map<int, double> minuteToOffset,
    required double totalHeight,
    required TaskProvider taskProvider,
  }) {
    final taskTops = <String, double>{};
    int slotIndex = 0;
    int lastHour = -1;

    for (final task in allTasks) {
      final hour = task.startTime.hour;
      if (hour != lastHour) {
        slotIndex = 0;
        lastHour = hour;
      }
      final base = minuteToOffset[hour * 60] ?? 0.0;
      taskTops[task.id] = base + slotIndex * (_cardHeight + _cardGap);
      slotIndex++;
    }

    return DragTarget<Task>(
      key: _scheduleAreaKey,
      onWillAccept: (_) => true,
      onAcceptWithDetails: (details) => _handleDrop(
        details,
        startHour,
        endHour,
        hourHeightMap,
        taskProvider,
        _scheduleAreaKey,
      ),
      builder: (context, _, __) {
        return Listener(
          onPointerMove: (e) => _handlePointerMove(e, startHour, endHour, hourHeightMap),
          child: SingleChildScrollView(
            controller: _scheduleScrollController,
            child: SizedBox(
              height: totalHeight - 20.h,
              child: Stack(
                children: [
                  _buildDynamicHourLines(startHour, endHour, hourHeightMap, allTasks),
                  ...allTasks.map((task) {
                    final top = taskTops[task.id]!;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 16.w,
                      child: _buildDraggableCard(task),
                    );
                  }),
                  if (_previewTime != null && _previewTop != null)
                    Positioned(
                      top: _previewTop! - 10.h,
                      left: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8.r)),
                        child: Text(
                          _previewTime!,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold),
                        ),
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

  void _handlePointerMove(
      PointerMoveEvent e,
      int startHour,
      int endHour,
      Map<int, double> hourHeightMap,
      ) {
    if (_draggedTask == null) return;

    _pointerOffset = e.position;

    final renderBox = _scheduleAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(e.position);
    final dy = localPos.dy + _scheduleScrollController.offset;

    final closestMinute = _getClosestMinute(dy, startHour, endHour, hourHeightMap);
    final hour = closestMinute ~/ 60;
    final minute = closestMinute % 60;
    final time = DateTime(2025, 1, 1, hour, minute);

    setState(() {
      _previewTime = DateFormat('h:mm a').format(time);
      _previewTop = _getMinuteOffset(closestMinute, startHour, hourHeightMap);
    });
  }


  // ────────────────────── DROP LOGIC (FINAL - PAST/FUTURE AUTO-CHECK) ──────────────────────
  void _handleDrop(
      DragTargetDetails<Task> details,
      int startHour,
      int endHour,
      Map<int, double> hourHeightMap,
      TaskProvider tp,
      GlobalKey scheduleKey,
      ) {
    final renderBox = scheduleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localOffset = renderBox.globalToLocal(details.offset);
    final dy = localOffset.dy + _scheduleScrollController.offset;

    final closestMinute = _getClosestMinute(dy, startHour, endHour, hourHeightMap);
    final hour = closestMinute ~/ 60;
    final minute = closestMinute % 60;

    final today = DateTime.now();
    final newStart = DateTime(today.year, today.month, today.day, hour, minute);
    final newEnd = newStart.add(details.data.duration);

    // AUTO-CHECK / UNCHECK BASED ON END TIME
    final shouldBeCompleted = newEnd.isBefore(DateTime.now());

    if (details.data.isCompleted != shouldBeCompleted) {
      tp.toggleTaskCompletion(details.data.id);
    }

    // Update time
    tp.updateTaskTime(details.data.id, newStart);

    setState(() {
      _previewTime = null;
      _previewTop = null;
    });
  }

// ... [Rest of the file remains 100% unchanged] ...

  double _getMinuteOffset(int minuteOfDay, int startHour, Map<int, double> hourHeightMap) {
    final h = minuteOfDay ~/ 60;
    double offset = 0.0;
    for (int hour = startHour; hour < h; hour++) {
      offset += hourHeightMap[hour]!;
    }
    final pixelsPerMinute = hourHeightMap[h]! / 60.0;
    return offset + (minuteOfDay % 60) * pixelsPerMinute;
  }

  int _getClosestMinute(double dy, int startHour, int endHour,
      Map<int, double> hourHeightMap) {
    double cumulative = 0.0;
    double minDist = double.infinity;
    int closest = startHour * 60;

    for (int h = startHour; h <= endHour; h++) {
      final hourHeight = hourHeightMap[h]!;
      final pixelsPerMinute = hourHeight / 60.0;
      for (int m = 0; m < 60; m++) {
        final minuteOffset = cumulative + m * pixelsPerMinute;
        final dist = (minuteOffset - dy).abs();
        if (dist < minDist) {
          minDist = dist;
          closest = h * 60 + m;
        }
      }
      cumulative += hourHeight;
    }
    return closest.clamp(startHour * 60, endHour * 60 + 59);
  }

  // ────── DRAGGABLE CARD ──────
  Widget _buildDraggableCard(Task task) {
    final isFaded = _isFaded(task);
    final hasStrikethrough = _hasStrikethrough(task);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -6.w,
          top: 0,
          child: Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: task.isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
        ),
        LongPressDraggable<Task>(
          data: task,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(
                  width: MediaQuery.of(context).size.width - 100.w,
                  child: _buildCardContent(task, true, true)),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: _buildCardContent(task, isFaded, hasStrikethrough)),
          onDragStarted: () {
            _draggedTask = task;
            _startAutoScroll();
            setState(() => _previewTime = _previewTop = null);
          },
          onDragEnd: (_) {
            _draggedTask = null;
            _stopAutoScroll();
            setState(() => _previewTime = _previewTop = null);
          },
          child: GestureDetector(
            onTap: () => context.push('/task-details', extra: task),
            child: Padding(
                padding: EdgeInsets.only(left: 5.w),
                child: _buildCardContent(task, isFaded, hasStrikethrough)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(Task task, bool faded, bool strikethrough) {
    return Opacity(
      opacity: faded ? 0.4 : 1.0,
      child: Container(
        height: _cardHeight.h,
        padding: EdgeInsets.all(8.w),
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
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
                        color: Colors.green[700],
                        fontFamily: 'Poppins'),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: task.isCompleted ? Colors.grey[600] : Colors.black87,
                      fontFamily: 'Poppins',
                      decoration: strikethrough ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: task.tags
                        .map((tg) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                          color: tg.backgroundColor,
                          borderRadius: BorderRadius.circular(6.r)),
                      child: Text(
                        tg.name,
                        style: TextStyle(
                            color: tg.textColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins'),
                      ),
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                      SizedBox(width: 2.w),
                      Text(
                        _formatDuration(task.duration),
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCheckbox(
              isChecked: task.isCompleted,
              onTap: () => Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(task.id),
              size: 30.w,
              iconSize: 26.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ────── CHECKBOX ──────
  Widget _buildCheckbox({
    required bool isChecked,
    required VoidCallback onTap,
    required double size,
    required double iconSize,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: isChecked ? Colors.grey[400]! : const Color(0xFF4CAF50),
                width: 2),
            color: isChecked ? Colors.grey[400] : Colors.transparent,
          ),
          child: isChecked
              ? Icon(Icons.check, size: iconSize, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  // ────── HOUR LINES ──────
  Widget _buildDynamicHourLines(
      int startHour, int endHour, Map<int, double> hourHeightMap, List<Task> tasks) {
    double cumulative = 0.0;
    return Stack(
      children: List.generate(endHour - startHour + 1, (i) {
        final hour = startHour + i;
        final height = hourHeightMap[hour]!;
        final hasTasks = tasks.any((t) => t.startTime.hour == hour);
        final color = hasTasks ? Colors.white : Colors.grey[400];

        final top = cumulative;
        cumulative += height;

        return Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Container(height: 1, color: color),
        );
      }),
    );
  }

  // ────── HEADER ──────
  Widget _buildHeader() {
    final now = DateTime.now();
    final date = DateFormat('EEEE, MMMM d, y').format(now);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset('assets/images/Saytask_logo.svg',
                  height: 24.h, width: 100.w),
            ],
          ),
          SizedBox(height: 16.h),
          Text('Today',
              style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins')),
          SizedBox(height: 6.h),
          Text(date,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins')),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => setState(() => _isCompactView = !_isCompactView),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isCompactView ? 'Expanded Schedule' : 'Compact View',
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins'),
                ),
                Icon(_isCompactView
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                    color: Colors.grey[700]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '$h hr${m > 0 ? ', $m min' : ''}' : '$m min';
  }

  // ────── AUTO-SCROLL ──────
  void _startAutoScroll() async {
    _autoScrolling = true;
    final renderBox = _scheduleAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    while (_autoScrolling && _draggedTask != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 16));

      if (_pointerOffset == null) continue;

      final localY = renderBox.globalToLocal(_pointerOffset!).dy;
      final maxScroll = _scheduleScrollController.position.maxScrollExtent;
      final current = _scheduleScrollController.offset;
      double delta = 0;

      if (localY < _scrollThreshold) {
        delta = -_scrollSpeed * (1 - localY / _scrollThreshold);
      } else if (localY > renderBox.size.height - _scrollThreshold) {
        final overflow = localY - (renderBox.size.height - _scrollThreshold);
        delta = _scrollSpeed * (1 + overflow / _scrollThreshold);
      }

      final newOffset = (current + delta).clamp(0.0, maxScroll);
      if ((newOffset - current).abs() > 0.1) {
        _scheduleScrollController.jumpTo(newOffset);
        _timelineScrollController.jumpTo(newOffset);
      }
    }
  }

  void _stopAutoScroll() => _autoScrolling = false;
}




// this code is okay only faded and strikethrough logic needs to be fixed
//
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:saytask/res/color.dart';
// import '../../model/today_task_model.dart';
// import '../../repository/today_task_service.dart';
// import 'dart:async';
//
// class TodayScreen extends StatefulWidget {
//   const TodayScreen({super.key});
//
//   @override
//   State<TodayScreen> createState() => _TodayScreenState();
// }
//
// class _TodayScreenState extends State<TodayScreen> {
//   final ScrollController _mainScrollController = ScrollController();
//   final ScrollController _scheduleScrollController = ScrollController();
//   final ScrollController _timelineScrollController = ScrollController();
//
//   // ────── Layout constants ──────
//   static const double _cardHeight = 120.0;
//   static const double _cardGap = 5.0;
//   static const double _emptyHourHeight = 120.0; // ~2 h per minute
//
//   static const int _defaultStartHour = 6;
//   static const int _defaultEndHour = 23;
//
//   bool _isCompactView = false;
//
//   Task? _draggedTask;
//   bool _autoScrolling = false;
//   static const double _scrollThreshold = 80.0;
//   static const double _scrollSpeed = 10.0;
//   Offset? _pointerOffset;
//
//   Timer? _autoCompletionTimer;
//
//   // Drag preview
//   String? _previewTime;
//   double? _previewTop;
//
//   // ──────────────────────────────────────────────────────────────
//   // Lifecycle
//   // ──────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     _syncScrollControllers();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final tp = Provider.of<TaskProvider>(context, listen: false);
//       tp.setTasks(_initializeTasks());
//       _startAutoCompletionTimer();
//     });
//   }
//
//   void _syncScrollControllers() {
//     _scheduleScrollController.addListener(() {
//       if (_timelineScrollController.offset != _scheduleScrollController.offset) {
//         _timelineScrollController.jumpTo(_scheduleScrollController.offset);
//       }
//     });
//     _timelineScrollController.addListener(() {
//       if (_scheduleScrollController.offset != _timelineScrollController.offset) {
//         _scheduleScrollController.jumpTo(_timelineScrollController.offset);
//       }
//     });
//   }
//
//   void _startAutoCompletionTimer() {
//     _autoCompletionTimer?.cancel();
//     _autoCompletionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       if (!mounted) return;
//       final tp = Provider.of<TaskProvider>(context, listen: false);
//       final now = DateTime.now();
//       for (final t in tp.tasks) {
//         if (now.isAfter(t.startTime.add(t.duration)) && !t.isCompleted) {
//           tp.toggleTaskCompletion(t.id);
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _autoCompletionTimer?.cancel();
//     _mainScrollController.dispose();
//     _scheduleScrollController.dispose();
//     _timelineScrollController.dispose();
//     super.dispose();
//   }
//
//   // ──────────────────────────────────────────────────────────────
//   // SAMPLE DATA
//   // ──────────────────────────────────────────────────────────────
//   List<Task> _initializeTasks() {
//     final today = DateTime.now();
//     return [
//       Task(
//         id: '1',
//         title: 'Team-meeting preparation',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 8, 0),
//         duration: const Duration(hours: 1),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFEDE7F6), textColor: const Color(0xFF7E57C2)),
//           Tag(name: 'Urgent', backgroundColor: const Color(0xFFFFEBEE), textColor: const Color(0xFFD32F2F)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '2',
//         title: 'Buy groceries',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 9, 0),
//         duration: const Duration(hours: 1, minutes: 30),
//         tags: [
//           Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
//           Tag(name: 'Shopping', backgroundColor: const Color(0xFFFFF1E0), textColor: const Color(0xFFF9A825)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '3',
//         title: 'Morning coffee with client',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 9, 30),
//         duration: const Duration(minutes: 45),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFFCE4EC), textColor: const Color(0xFFEC407A)),
//           Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '4',
//         title: 'Quick phone check-in',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 9, 45),
//         duration: const Duration(minutes: 5),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFE8F5E9), textColor: const Color(0xFF43A047)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '5',
//
//
//         title: 'Client Meeting',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 11, 0),
//         duration: const Duration(minutes: 45),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFFCE4EC), textColor: const Color(0xFFEC407A)),
//           Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<TaskProvider>(
//       builder: (context, tp, _) => _isCompactView
//           ? _buildCompactView(tp)
//           : _buildExpandedView(tp),
//     );
//   }
//
//   // ──────────────────────────────────────────────────────────────
//   // COMPACT VIEW
//   // ──────────────────────────────────────────────────────────────
//   Widget _buildCompactView(TaskProvider tp) {
//     final sorted = List<Task>.from(tp.tasks)
//       ..sort((a, b) => a.startTime.compareTo(b.startTime));
//
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: ListView.builder(
//                 controller: _mainScrollController,
//                 padding: EdgeInsets.symmetric(horizontal: 16.w),
//                 itemCount: sorted.length,
//                 itemBuilder: (_, i) => _buildCompactTaskItem(sorted[i]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCompactTaskItem(Task t) {
//     final bool faded = t.isCompleted || DateTime.now().isAfter(t.startTime.add(t.duration));
//
//     return Padding(
//       padding: EdgeInsets.only(bottom: 12.h),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 40.w,
//             child: Text(
//               DateFormat('h a').format(t.startTime),
//               style: TextStyle(fontSize: 12.sp, color: AppColors.black, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
//             ),
//           ),
//           Column(
//             children: [
//               SizedBox(height: 6.h),
//               Container(
//                 width: 10.w,
//                 height: 10.w,
//                 decoration: BoxDecoration(
//                   color: t.isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: GestureDetector(
//               onTap: () => context.push('/task-details', extra: t),
//               child: _buildCompactCard(t, faded),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCompactCard(Task t, bool faded) {
//     return Opacity(
//       opacity: faded ? 0.4 : 1.0,
//       child: Container(
//         padding: EdgeInsets.all(12.w),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: Colors.grey[200]!),
//           borderRadius: BorderRadius.circular(12.r),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     t.title,
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.bold,
//                       color: t.isCompleted ? Colors.grey[600] : Colors.black87,
//                       fontFamily: 'Poppins',
//                       decoration: t.isCompleted ? TextDecoration.lineThrough : null,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 8.h),
//                   Wrap(
//                     spacing: 6.w,
//                     runSpacing: 4.h,
//                     children: t.tags
//                         .map((tg) => Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                       decoration: BoxDecoration(
//                         color: tg.backgroundColor,
//                         borderRadius: BorderRadius.circular(6.r),
//                       ),
//                       child: Text(
//                         tg.name,
//                         style: TextStyle(
//                             color: tg.textColor,
//                             fontSize: 11.sp,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Poppins'),
//                       ),
//                     ))
//                         .toList(),
//                   ),
//                   SizedBox(height: 6.h),
//                   Row(
//                     children: [
//                       Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
//                       SizedBox(width: 4.w),
//                       Text(
//                         _formatDuration(t.duration),
//                         style: TextStyle(
//                             fontSize: 12.sp,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                             fontFamily: 'Poppins'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             _buildCheckbox(
//               isChecked: t.isCompleted,
//               onTap: () => Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(t.id),
//               size: 30.w,
//               iconSize: 26.sp,
//             ),
//             SizedBox(width: 12.w),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ──────────────────────────────────────────────────────────────
//   // EXPANDED VIEW
//   // ──────────────────────────────────────────────────────────────
//   Widget _buildExpandedView(TaskProvider tp) {
//     const int startHour = _defaultStartHour;
//     const int endHour = _defaultEndHour;
//
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           controller: _mainScrollController,
//           child: Column(
//             children: [
//               _buildHeader(),
//               Consumer<TaskProvider>(
//                 builder: (context, tp, _) {
//                   final allTasks = List<Task>.from(tp.tasks)
//                     ..sort((a, b) => a.startTime.compareTo(b.startTime));
//
//                   // ---- compute layout (Map version) ----
//                   final layout = _computeTimelineLayout(allTasks, startHour, endHour);
//                   final hourHeightMap = layout['hourHeightMap'] as Map<int, double>;
//                   final minuteToOffset = layout['minuteToOffset'] as Map<int, double>;
//                   final totalHeight = layout['totalHeight'] as double;
//
//                   return SizedBox(
//                     height: totalHeight,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildDynamicTimeline(startHour, endHour, hourHeightMap),
//                         _buildScrollableDivider(startHour, endHour, hourHeightMap),
//                         Expanded(
//                           child: _buildScheduleArea(
//                             startHour: startHour,
//                             endHour: endHour,
//                             allTasks: allTasks,
//                             hourHeightMap: hourHeightMap,
//                             minuteToOffset: minuteToOffset,
//                             totalHeight: totalHeight,
//                             taskProvider: tp,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ────────────────────── LAYOUT CALCULATION (Map version) ──────────────────────
//   Map<String, dynamic> _computeTimelineLayout(
//       List<Task> tasks,
//       int startHour,
//       int endHour,
//       ) {
//     final tasksByMinute = <int, List<Task>>{};
//     for (final t in tasks) {
//       final minuteOfDay = t.startTime.hour * 60 + t.startTime.minute;
//       if (minuteOfDay >= startHour * 60 && minuteOfDay <= endHour * 60 + 59) {
//         tasksByMinute.putIfAbsent(minuteOfDay, () => []).add(t);
//       }
//     }
//
//     final hourHeightMap = <int, double>{};
//     for (int h = startHour; h <= endHour; h++) {
//       final minuteStart = h * 60;
//       final tasksInHour = tasksByMinute.entries
//           .where((e) => e.key >= minuteStart && e.key < minuteStart + 60)
//           .length;
//       hourHeightMap[h] = tasksInHour > 0 ? tasksInHour * (_cardHeight + _cardGap) : _emptyHourHeight;
//     }
//
//     final minuteToOffset = <int, double>{};
//     double cumulative = 0.0;
//     for (int h = startHour; h <= endHour; h++) {
//       final hourHeight = hourHeightMap[h]!;
//       final pixelsPerMinute = hourHeight / 60.0;
//       for (int m = 0; m < 60; m++) {
//         minuteToOffset[h * 60 + m] = cumulative + m * pixelsPerMinute;
//       }
//       cumulative += hourHeight;
//     }
//
//     return {
//       'hourHeightMap': hourHeightMap,
//       'minuteToOffset': minuteToOffset,
//       'totalHeight': cumulative + 20.h,
//     };
//   }
//
//   // ────────────────────── TIMELINE & DIVIDER ──────────────────────
//   Widget _buildDynamicTimeline(int startHour, int endHour, Map<int, double> hourHeightMap) {
//     return SizedBox(
//       width: 60.w,
//       child: SingleChildScrollView(
//         controller: _timelineScrollController,
//         physics: const NeverScrollableScrollPhysics(),
//         child: Column(
//           children: List.generate(endHour - startHour + 1, (i) {
//             final hour = startHour + i;
//             return SizedBox(
//               height: hourHeightMap[hour],
//               child: Align(
//                 alignment: Alignment.topCenter,
//                 child: Padding(
//                   padding: EdgeInsets.only(top: 8.h),
//                   child: Text(
//                     DateFormat('h a').format(DateTime(2025, 1, 1, hour)),
//                     style: TextStyle(
//                         fontSize: 12.sp,
//                         color: AppColors.black,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'Poppins'),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildScrollableDivider(int startHour, int endHour, Map<int, double> hourHeightMap) {
//     return Container(
//       width: 1.w,
//       color: Colors.grey[300],
//       margin: EdgeInsets.only(top: 1.h),
//       child: SingleChildScrollView(
//         controller: _timelineScrollController,
//         physics: const NeverScrollableScrollPhysics(),
//         child: Column(
//           children: List.generate(endHour - startHour + 1, (i) {
//             final height = hourHeightMap[startHour + i]!;
//             return Container(height: height, color: Colors.grey[300]);
//           }),
//         ),
//       ),
//     );
//   }
//
//   // ────────────────────── SCHEDULE AREA ──────────────────────
//   Widget _buildScheduleArea({
//     required int startHour,
//     required int endHour,
//     required List<Task> allTasks,
//     required Map<int, double> hourHeightMap,
//     required Map<int, double> minuteToOffset,
//     required double totalHeight,
//     required TaskProvider taskProvider,
//   }) {
//     // ---- card tops (no overlap) ----
//     final taskTops = <String, double>{};
//     double hourBase = 0.0;
//     int lastHour = -1;
//
//     for (int i = 0; i < allTasks.length; i++) {
//       final task = allTasks[i];
//       final hour = task.startTime.hour;
//
//       if (hour != lastHour) {
//         hourBase = minuteToOffset[hour * 60] ?? 0.0;
//         lastHour = hour;
//       }
//
//       final slotIndex = allTasks.sublist(0, i).where((t) => t.startTime.hour == hour).length;
//       taskTops[task.id] = hourBase + slotIndex * (_cardHeight + _cardGap);
//     }
//
//     return Listener(
//       onPointerMove: (e) => _handlePointerMove(e, startHour, endHour, hourHeightMap),
//       child: DragTarget<Task>(
//         onWillAccept: (_) => true,
//         onAcceptWithDetails: (details) =>
//             _handleDrop(details, startHour, endHour, hourHeightMap, taskProvider),
//         builder: (context, _, __) => Stack(
//           children: [
//             SingleChildScrollView(
//               controller: _scheduleScrollController,
//               child: SizedBox(
//                 height: totalHeight - 20.h,
//                 child: Stack(
//                   children: [
//                     _buildDynamicHourLines(startHour, endHour, hourHeightMap, allTasks),
//                     ...allTasks.map((task) {
//                       final top = taskTops[task.id]!;
//                       return Positioned(
//                         top: top,
//                         left: 0,
//                         right: 16.w,
//                         child: _buildDraggableCard(task),
//                       );
//                     }),
//                     if (_previewTime != null && _previewTop != null)
//                       Positioned(
//                         top: _previewTop! - 10.h,
//                         left: 16.w,
//                         child: Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                           decoration: BoxDecoration(
//                               color: Colors.black87,
//                               borderRadius: BorderRadius.circular(8.r)),
//                           child: Text(
//                             _previewTime!,
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12.sp,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _handlePointerMove(PointerMoveEvent e, int startHour, int endHour,
//       Map<int, double> hourHeightMap) {
//     _pointerOffset = e.localPosition;
//     if (_draggedTask == null) return;
//
//     final dy = e.localPosition.dy + _scheduleScrollController.offset;
//     final closestMinute = _getClosestMinute(dy, startHour, endHour, hourHeightMap);
//     final hour = closestMinute ~/ 60;
//     final minute = closestMinute % 60;
//     final time = DateTime(2025, 1, 1, hour, minute);
//
//     setState(() {
//       _previewTime = DateFormat('h:mm a').format(time);
//       _previewTop = _getMinuteOffset(closestMinute, startHour, hourHeightMap);
//     });
//   }
//
//   void _handleDrop(
//       DragTargetDetails<Task> details,
//       int startHour,
//       int endHour,
//       Map<int, double> hourHeightMap,
//       TaskProvider tp) {
//     final rb = context.findRenderObject() as RenderBox;
//     final local = rb.globalToLocal(details.offset);
//     final dy = local.dy + _scheduleScrollController.offset;
//     final closestMinute = _getClosestMinute(dy, startHour, endHour, hourHeightMap);
//     final hour = closestMinute ~/ 60;
//     final minute = closestMinute % 60;
//     final newStart = DateTime(
//         details.data.startTime.year,
//         details.data.startTime.month,
//         details.data.startTime.day,
//         hour,
//         minute);
//
//     tp.updateTaskTime(details.data.id, newStart);
//     setState(() {
//       _previewTime = null;
//       _previewTop = null;
//     });
//   }
//
//   double _getMinuteOffset(int minuteOfDay, int startHour, Map<int, double> hourHeightMap) {
//     final h = minuteOfDay ~/ 60;
//     double offset = 0.0;
//     for (int hour = startHour; hour < h; hour++) {
//       offset += hourHeightMap[hour]!;
//     }
//     final pixelsPerMinute = hourHeightMap[h]! / 60.0;
//     return offset + (minuteOfDay % 60) * pixelsPerMinute;
//   }
//
//   int _getClosestMinute(double dy, int startHour, int endHour,
//       Map<int, double> hourHeightMap) {
//     double cumulative = 0.0;
//     double minDist = double.infinity;
//     int closest = startHour * 60;
//
//     for (int h = startHour; h <= endHour; h++) {
//       final hourHeight = hourHeightMap[h]!;
//       final pixelsPerMinute = hourHeight / 60.0;
//       for (int m = 0; m < 60; m++) {
//         final minuteOffset = cumulative + m * pixelsPerMinute;
//         final dist = (minuteOffset - dy).abs();
//         if (dist < minDist) {
//           minDist = dist;
//           closest = h * 60 + m;
//         }
//       }
//       cumulative += hourHeight;
//     }
//     return closest.clamp(startHour * 60, endHour * 60 + 59);
//   }
//
//   // ────── DRAGGABLE CARD ──────
//   Widget _buildDraggableCard(Task task) {
//     final bool faded = task.isCompleted ||
//         DateTime.now().isAfter(task.startTime.add(task.duration));
//
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Positioned(
//           left: -6.w,
//           top: 0,
//           child: Container(
//             width: 10.w,
//             height: 10.w,
//             decoration: BoxDecoration(
//               color: task.isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
//               shape: BoxShape.circle,
//             ),
//           ),
//         ),
//         LongPressDraggable<Task>(
//           data: task,
//           feedback: Material(
//             color: Colors.transparent,
//             child: Opacity(
//               opacity: 0.9,
//               child: SizedBox(
//                   width: MediaQuery.of(context).size.width - 100.w,
//                   child: _buildCardContent(task, true)),
//             ),
//           ),
//           childWhenDragging:
//           Opacity(opacity: 0.3, child: _buildCardContent(task, faded)),
//           onDragStarted: () {
//             _draggedTask = task;
//             _startAutoScroll();
//             setState(() => _previewTime = _previewTop = null);
//           },
//           onDragEnd: (_) {
//             _draggedTask = null;
//             _stopAutoScroll();
//             setState(() => _previewTime = _previewTop = null);
//           },
//           child: GestureDetector(
//             onTap: () => context.push('/task-details', extra: task),
//             child: Padding(
//                 padding: EdgeInsets.only(left: 5.w),
//                 child: _buildCardContent(task, faded)),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCardContent(Task task, bool faded) {
//     return Opacity(
//       opacity: faded ? 0.4 : 1.0,
//       child: Container(
//         height: _cardHeight.h,
//         padding: EdgeInsets.all(8.w),
//         margin: EdgeInsets.only(bottom: 2.h),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: Colors.grey[200]!),
//           borderRadius: BorderRadius.circular(12.r),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     DateFormat('h:mm a').format(task.startTime),
//                     style: TextStyle(
//                         fontSize: 10.sp,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[700],
//                         fontFamily: 'Poppins'),
//                   ),
//                   SizedBox(height: 4.h),
//                   Text(
//                     task.title,
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       fontWeight: FontWeight.bold,
//                       color: task.isCompleted ? Colors.grey[600] : Colors.black87,
//                       fontFamily: 'Poppins',
//                       decoration:
//                       task.isCompleted ? TextDecoration.lineThrough : null,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 4.h),
//                   Wrap(
//                     spacing: 8.w,
//                     runSpacing: 4.h,
//                     children: task.tags
//                         .map((tg) => Container(
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 8.w, vertical: 4.h),
//                       decoration: BoxDecoration(
//                           color: tg.backgroundColor,
//                           borderRadius: BorderRadius.circular(6.r)),
//                       child: Text(
//                         tg.name,
//                         style: TextStyle(
//                             color: tg.textColor,
//                             fontSize: 11.sp,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Poppins'),
//                       ),
//                     ))
//                         .toList(),
//                   ),
//                   SizedBox(height: 4.h),
//                   Row(
//                     children: [
//                       Icon(Icons.access_time,
//                           size: 12.sp, color: Colors.grey[600]),
//                       SizedBox(width: 2.w),
//                       Text(
//                         _formatDuration(task.duration),
//                         style: TextStyle(
//                             fontSize: 10.sp,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                             fontFamily: 'Poppins'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             _buildCheckbox(
//               isChecked: task.isCompleted,
//               onTap: () => Provider.of<TaskProvider>(context, listen: false)
//                   .toggleTaskCompletion(task.id),
//               size: 30.w,
//               iconSize: 26.sp,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ────── REUSABLE CHECKBOX (large tap area) ──────
//   Widget _buildCheckbox({
//     required bool isChecked,
//     required VoidCallback onTap,
//     required double size,
//     required double iconSize,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(24.r),
//       onTap: onTap,
//       child: Padding(
//         padding: EdgeInsets.all(12.w), // ~48×48 tap zone
//         child: Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(
//                 color: isChecked ? Colors.grey[400]! : const Color(0xFF4CAF50),
//                 width: 2),
//             color: isChecked ? Colors.grey[400] : Colors.transparent,
//           ),
//           child: isChecked
//               ? Icon(Icons.check, size: iconSize, color: Colors.white)
//               : null,
//         ),
//       ),
//     );
//   }
//
//   // ────── HOUR LINES (white if tasks exist) ──────
//   Widget _buildDynamicHourLines(
//       int startHour, int endHour, Map<int, double> hourHeightMap, List<Task> tasks) {
//     final tasksByMinute = <int, List<Task>>{};
//     for (final t in tasks) {
//       final m = t.startTime.hour * 60 + t.startTime.minute;
//       tasksByMinute.putIfAbsent(m, () => []).add(t);
//     }
//
//     double cumulative = 0.0;
//     return Stack(
//       children: List.generate(endHour - startHour + 1, (i) {
//         final hour = startHour + i;
//         final height = hourHeightMap[hour]!;
//         final minuteStart = hour * 60;
//         final hasTasks = tasksByMinute.keys
//             .any((k) => k >= minuteStart && k < minuteStart + 60);
//         final color = hasTasks ? Colors.white : Colors.grey[400];
//
//         final top = cumulative;
//         cumulative += height;
//
//         return Positioned(
//           top: top,
//           left: 0,
//           right: 0,
//           child: Container(height: 1, color: color),
//         );
//       }),
//     );
//   }
//
//   // ────── HEADER ──────
//   Widget _buildHeader() {
//     final now = DateTime.now();
//     final date = DateFormat('EEEE, MMMM d, y').format(now);
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SvgPicture.asset('assets/images/Saytask_logo.svg',
//                   height: 24.h, width: 100.w),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           Text('Today',
//               style: TextStyle(
//                   fontSize: 24.sp,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'Poppins')),
//           SizedBox(height: 6.h),
//           Text(date,
//               style: TextStyle(
//                   fontSize: 12.sp,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                   fontFamily: 'Poppins')),
//           SizedBox(height: 10.h),
//           GestureDetector(
//             onTap: () => setState(() => _isCompactView = !_isCompactView),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   _isCompactView ? 'Expanded Schedule' : 'Compact View',
//                   style: TextStyle(
//                       fontSize: 14.sp,
//                       color: Colors.grey[800],
//                       fontWeight: FontWeight.w500,
//                       fontFamily: 'Poppins'),
//                 ),
//                 Icon(_isCompactView
//                     ? Icons.keyboard_arrow_down
//                     : Icons.keyboard_arrow_up,
//                     color: Colors.grey[700]),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes % 60;
//     return h > 0 ? '$h hr${m > 0 ? ', $m min' : ''}' : '$m min';
//   }
//
//   // ────── AUTO-SCROLL ──────
//   void _startAutoScroll() async {
//     _autoScrolling = true;
//     while (_autoScrolling && _draggedTask != null && mounted && _pointerOffset != null) {
//       await Future.delayed(const Duration(milliseconds: 50));
//
//       final y = _pointerOffset!.dy;
//       final max = _scheduleScrollController.position.maxScrollExtent;
//       final cur = _scheduleScrollController.offset;
//       double delta = 0;
//
//       if (y < _scrollThreshold) {
//         delta = -_scrollSpeed * (1 - y / _scrollThreshold);
//       } else if (y > MediaQuery.of(context).size.height - _scrollThreshold) {
//         final dist = y - (MediaQuery.of(context).size.height - _scrollThreshold);
//         delta = _scrollSpeed * (1 + dist / _scrollThreshold);
//       }
//
//       final newOff = (cur + delta).clamp(0.0, max);
//       _scheduleScrollController.jumpTo(newOff);
//       _timelineScrollController.jumpTo(newOff);
//     }
//   }
//
//   void _stopAutoScroll() => _autoScrolling = false;
// }
//












// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:saytask/res/color.dart';
// import '../../model/today_task_model.dart';
// import '../../repository/today_task_service.dart';
// import 'dart:async';
//
// class TodayScreen extends StatefulWidget {
//   const TodayScreen({super.key});
//
//   @override
//   State<TodayScreen> createState() => _TodayScreenState();
// }
//
// class _TodayScreenState extends State<TodayScreen> {
//   final ScrollController _mainScrollController = ScrollController();
//   final ScrollController _scheduleScrollController = ScrollController();
//   final ScrollController _timelineScrollController = ScrollController();
//
//   // Base dimensions
//   final double _cardHeight = 120.h;
//   final double _cardGap = 5.w;
//   final double _emptyHourHeight = 120.h; // 2 h per minute
//
//   final int _defaultStartHour = 6;
//   final int _defaultEndHour = 23;
//
//   bool _isCompactView = false;
//
//   Task? _draggedTask;
//   bool _autoScrolling = false;
//   final double _scrollThreshold = 80;
//   final double _scrollSpeed = 10;
//   Offset? _pointerOffset;
//
//   Timer? _autoCompletionTimer;
//
//   // Drag preview
//   String? _previewTime;
//   double? _previewTop;
//
//   // ──────────────────────────────────────────────────────────────
//   // Lifecycle
//   // ──────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     _scheduleScrollController.addListener(() {
//       _timelineScrollController.jumpTo(_scheduleScrollController.offset);
//     });
//     _timelineScrollController.addListener(() {
//       _scheduleScrollController.jumpTo(_timelineScrollController.offset);
//     });
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final tp = Provider.of<TaskProvider>(context, listen: false);
//       tp.setTasks(_initializeTasks());
//       _startAutoCompletionTimer();
//     });
//   }
//
//   void _startAutoCompletionTimer() {
//     _autoCompletionTimer?.cancel();
//     _autoCompletionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       if (!mounted) return;
//       final tp = Provider.of<TaskProvider>(context, listen: false);
//       final now = DateTime.now();
//       for (final t in tp.tasks) {
//         if (now.isAfter(t.startTime.add(t.duration)) && !t.isCompleted) {
//           tp.toggleTaskCompletion(t.id);
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _autoCompletionTimer?.cancel();
//     _mainScrollController.dispose();
//     _scheduleScrollController.dispose();
//     _timelineScrollController.dispose();
//     super.dispose();
//   }
//
//   // ──────────────────────────────────────────────────────────────
//   // SAMPLE DATA — Matches Screenshot
//   // ──────────────────────────────────────────────────────────────
//   List<Task> _initializeTasks() {
//     final today = DateTime.now();
//     return [
//       Task(
//         id: '1',
//         title: 'Team-meeting preparation',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 8, 0),
//         duration: const Duration(hours: 1),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFEDE7F6), textColor: const Color(0xFF7E57C2)),
//           Tag(name: 'Urgent', backgroundColor: const Color(0xFFFFEBEE), textColor: const Color(0xFFD32F2F)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '2',
//         title: 'Buy groceries',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 9, 0),
//         duration: const Duration(hours: 1, minutes: 30),
//         tags: [
//           Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
//           Tag(name: 'Shopping', backgroundColor: const Color(0xFFFFF1E0), textColor: const Color(0xFFF9A825)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '3',
//         title: 'Morning coffee with client',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 9, 30),
//         duration: const Duration(minutes: 45),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFFCE4EC), textColor: const Color(0xFFEC407A)),
//           Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '4',
//         title: 'Quick phone check-in',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 9, 45),
//         duration: const Duration(minutes: 5),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFE8F5E9), textColor: const Color(0xFF43A047)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//       Task(
//         id: '5',
//         title: 'Client Meeting',
//         description: '',
//         startTime: DateTime(today.year, today.month, today.day, 11, 0),
//         duration: const Duration(minutes: 45),
//         tags: [
//           Tag(name: 'Work', backgroundColor: const Color(0xFFFCE4EC), textColor: const Color(0xFFEC407A)),
//           Tag(name: 'Important', backgroundColor: const Color(0xFFE3F2FD), textColor: const Color(0xFF42A5F5)),
//         ],
//         reminders: [],
//         isCompleted: false,
//       ),
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<TaskProvider>(
//       builder: (context, tp, _) => _isCompactView
//           ? _buildCompactView(tp)
//           : _buildExpandedView(tp),
//     );
//   }
//
//   // ──────────────────────────────────────────────────────────────
//   // COMPACT VIEW – Unchanged
//   // ──────────────────────────────────────────────────────────────
//   Widget _buildCompactView(TaskProvider tp) {
//     final sorted = List<Task>.from(tp.tasks)
//       ..sort((a, b) => a.startTime.compareTo(b.startTime));
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: ListView.builder(
//                 controller: _mainScrollController,
//                 padding: EdgeInsets.symmetric(horizontal: 16.w),
//                 itemCount: sorted.length,
//                 itemBuilder: (_, i) {
//                   final t = sorted[i];
//                   return Padding(
//                     padding: EdgeInsets.only(bottom: 12.h),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         SizedBox(
//                           width: 40.w,
//                           child: Text(DateFormat('h a').format(t.startTime),
//                               style: TextStyle(fontSize: 12.sp, color: AppColors.black, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
//                         ),
//                         Column(children: [
//                           SizedBox(height: 6.h),
//                           Container(
//                             width: 10.w,
//                             height: 10.w,
//                             decoration: BoxDecoration(
//                                 color: t.isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
//                                 shape: BoxShape.circle),
//                           ),
//                         ]),
//                         SizedBox(width: 12.w),
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: () => context.push('/task-details', extra: t),
//                             child: _compactCard(t),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _compactCard(Task t) {
//     final bool faded = t.isCompleted || DateTime.now().isAfter(t.startTime.add(t.duration));
//
//     return Opacity(
//       opacity: faded ? 0.4 : 1.0,
//       child: Container(
//         padding: EdgeInsets.all(12.w),
//         decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: Colors.grey[200]!),
//             borderRadius: BorderRadius.circular(12.r)),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(t.title,
//                       style: TextStyle(
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.bold,
//                           color: t.isCompleted ? Colors.grey[600] : Colors.black87,
//                           fontFamily: 'Poppins',
//                           decoration: t.isCompleted ? TextDecoration.lineThrough : null),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis),
//                   SizedBox(height: 8.h),
//                   Wrap(
//                       spacing: 6.w,
//                       runSpacing: 4.h,
//                       children: t.tags
//                           .map((tg) => Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                           decoration: BoxDecoration(color: tg.backgroundColor, borderRadius: BorderRadius.circular(6.r)),
//                           child: Text(tg.name,
//                               style: TextStyle(color: tg.textColor, fontSize: 11.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))))
//                           .toList()),
//                   SizedBox(height: 6.h),
//                   Row(children: [
//                     Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
//                     SizedBox(width: 4.w),
//                     Text(_formatDuration(t.duration),
//                         style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
//                   ]),
//                 ],
//               ),
//             ),
//             GestureDetector(
//               onTap: () => Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(t.id),
//               child: Container(
//                 width: 20.w,
//                 height: 20.w,
//                 decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: t.isCompleted ? Colors.grey[400]! : const Color(0xFF4CAF50), width: 2),
//                     color: t.isCompleted ? Colors.grey[400] : Colors.transparent),
//                 child: t.isCompleted ? Icon(Icons.check, size: 14.sp, color: Colors.white) : null,
//               ),
//             ),
//             SizedBox(width: 12.w),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ──────────────────────────────────────────────────────────────
//   // EXPANDED VIEW – Chronological Cards
//   // ──────────────────────────────────────────────────────────────
//   Widget _buildExpandedView(TaskProvider tp) {
//     final int startHour = _defaultStartHour;
//     final int endHour = _defaultEndHour;
//
//     // Group tasks by minute
//     final Map<int, List<Task>> tasksByMinute = {};
//     for (final t in tp.tasks) {
//       final minuteOfDay = t.startTime.hour * 60 + t.startTime.minute;
//       if (minuteOfDay >= startHour * 60 && minuteOfDay <= endHour * 60 + 59) {
//         tasksByMinute.putIfAbsent(minuteOfDay, () => []).add(t);
//       }
//     }
//
//     // Compute hour height
//     final Map<int, double> hourHeightMap = {};
//     for (int h = startHour; h <= endHour; h++) {
//       final minuteStart = h * 60;
//       final tasksInHour = tasksByMinute.entries.where((e) => e.key >= minuteStart && e.key < minuteStart + 60).length;
//       final slotHeight = _cardHeight + _cardGap;
//       hourHeightMap[h] = tasksInHour > 0 ? tasksInHour * slotHeight : _emptyHourHeight;
//     }
//
//     // Pixel offset for every minute
//     final Map<int, double> minuteToOffset = {};
//     double cumulative = 0.0;
//     for (int h = startHour; h <= endHour; h++) {
//       final hourHeight = hourHeightMap[h]!;
//       final pixelsPerMinute = hourHeight / 60.0;
//       for (int m = 0; m < 60; m++) {
//         final minuteKey = h * 60 + m;
//         minuteToOffset[minuteKey] = cumulative + m * pixelsPerMinute;
//       }
//       cumulative += hourHeight;
//     }
//     final totalHeight = cumulative + 20.h;
//
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           controller: _mainScrollController,
//           child: Column(
//             children: [
//               _buildHeader(),
//               SizedBox(
//                 height: totalHeight,
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildDynamicTimeline(startHour, endHour, hourHeightMap),
//                     _buildScrollableDivider(startHour, endHour, hourHeightMap),
//                     Expanded(
//                       child: _buildScheduleArea(
//                         startHour: startHour,
//                         endHour: endHour,
//                         tasksByMinute: tasksByMinute,
//                         hourHeightMap: hourHeightMap,
//                         minuteToOffset: minuteToOffset,
//                         totalHeight: totalHeight,
//                         taskProvider: tp,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ────────────────────── TIMELINE ──────────────────────
//   Widget _buildDynamicTimeline(int startHour, int endHour, Map<int, double> hourHeightMap) {
//     return SizedBox(
//       width: 60.w,
//       child: SingleChildScrollView(
//         controller: _timelineScrollController,
//         physics: const NeverScrollableScrollPhysics(),
//         child: Column(
//           children: List.generate(endHour - startHour + 1, (i) {
//             final hour = startHour + i;
//             final height = hourHeightMap[hour]!;
//             return SizedBox(
//               height: height,
//               child: Align(
//                 alignment: Alignment.topCenter,
//                 child: Padding(
//                   padding: EdgeInsets.only(top: 8.h),
//                   child: Text(
//                     DateFormat('h a').format(DateTime(2025, 1, 1, hour)),
//                     style: TextStyle(fontSize: 12.sp, color: AppColors.black, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }
//
//   // ────────────────────── DIVIDER ──────────────────────
//   Widget _buildScrollableDivider(int startHour, int endHour, Map<int, double> hourHeightMap) {
//     return Container(
//       width: 1.w,
//       color: Colors.grey[300],
//       margin: EdgeInsets.only(top: 1.h),
//       child: SingleChildScrollView(
//         controller: _timelineScrollController,
//         physics: const NeverScrollableScrollPhysics(),
//         child: Column(
//           children: List.generate(endHour - startHour + 1, (i) {
//             final height = hourHeightMap[startHour + i]!;
//             return Container(height: height, color: Colors.grey[300]);
//           }),
//         ),
//       ),
//     );
//   }
//
//   // ────────────────────── SCHEDULE AREA ──────────────────────
//   Widget _buildScheduleArea({
//     required int startHour,
//     required int endHour,
//     required Map<int, List<Task>> tasksByMinute, // dummy
//     required Map<int, double> hourHeightMap,     // dummy
//     required Map<int, double> minuteToOffset,    // dummy
//     required double totalHeight,                 // dummy
//     required TaskProvider taskProvider,
//   }) {
//     return Consumer<TaskProvider>(
//       builder: (context, tp, _) {
//         final allTasks = List<Task>.from(tp.tasks)
//           ..sort((a, b) => a.startTime.compareTo(b.startTime));
//
//         // ── DYNAMIC RECALCULATION ──
//         final Map<int, List<Task>> currentTasksByMinute = {};
//         for (final t in allTasks) {
//           final minuteOfDay = t.startTime.hour * 60 + t.startTime.minute;
//           if (minuteOfDay >= startHour * 60 && minuteOfDay <= endHour * 60 + 59) {
//             currentTasksByMinute.putIfAbsent(minuteOfDay, () => []).add(t);
//           }
//         }
//
//         final Map<int, double> currentHourHeightMap = {};
//         for (int h = startHour; h <= endHour; h++) {
//           final minuteStart = h * 60;
//           final tasksInHour = currentTasksByMinute.entries
//               .where((e) => e.key >= minuteStart && e.key < minuteStart + 60)
//               .length;
//           final slotHeight = _cardHeight + _cardGap;
//           currentHourHeightMap[h] = tasksInHour > 0 ? tasksInHour * slotHeight : _emptyHourHeight;
//         }
//
//         final Map<int, double> currentMinuteToOffset = {};
//         double cumulative = 0.0;
//         for (int h = startHour; h <= endHour; h++) {
//           final hourHeight = currentHourHeightMap[h]!;
//           final pixelsPerMinute = hourHeight / 60.0;
//           for (int m = 0; m < 60; m++) {
//             final minuteKey = h * 60 + m;
//             currentMinuteToOffset[minuteKey] = cumulative + m * pixelsPerMinute;
//           }
//           cumulative += hourHeight;
//         }
//         final currentTotalHeight = cumulative + 20.h;
//
//         // ── CARD POSITIONING (Chronological, one below another) ──
//         final Map<String, double> taskTops = {};
//         double cumulativeTop = 0.0;
//
//         for (int i = 0; i < allTasks.length; i++) {
//           final task = allTasks[i];
//           final minuteKey = task.startTime.hour * 60 + task.startTime.minute;
//
//           final isFirstInHour = i == 0 ||
//               (allTasks[i - 1].startTime.hour != task.startTime.hour);
//
//           if (isFirstInHour && currentMinuteToOffset.containsKey(minuteKey)) {
//             cumulativeTop = currentMinuteToOffset[minuteKey]!;
//           }
//
//           taskTops[task.id] = cumulativeTop;
//           cumulativeTop += _cardHeight + _cardGap;
//         }
//
//         return Listener(
//           onPointerMove: (e) {
//             _pointerOffset = e.localPosition;
//             if (_draggedTask != null) {
//               final dy = e.localPosition.dy + _scheduleScrollController.offset;
//               final closestMinute = _getClosestMinute(dy, startHour, endHour, currentHourHeightMap);
//               final hour = closestMinute ~/ 60;
//               final minute = closestMinute % 60;
//               final time = DateTime(2025, 1, 1, hour, minute);
//               setState(() {
//                 _previewTime = DateFormat('h:mm a').format(time);
//                 _previewTop = _getMinuteOffset(closestMinute, startHour, currentHourHeightMap);
//               });
//             }
//           },
//           child: DragTarget<Task>(
//             onWillAccept: (_) => true,
//             onAcceptWithDetails: (details) {
//               final rb = context.findRenderObject() as RenderBox;
//               final local = rb.globalToLocal(details.offset);
//               final dy = local.dy + _scheduleScrollController.offset;
//               final closestMinute = _getClosestMinute(dy, startHour, endHour, currentHourHeightMap);
//               final hour = closestMinute ~/ 60;
//               final minute = closestMinute % 60;
//               final task = details.data;
//               final newStart = DateTime(task.startTime.year, task.startTime.month, task.startTime.day, hour, minute);
//
//               tp.updateTaskTime(task.id, newStart);
//               setState(() {
//                 _previewTime = null;
//                 _previewTop = null;
//               });
//             },
//             builder: (context, _, __) {
//               return Stack(
//                 children: [
//                   SingleChildScrollView(
//                     controller: _scheduleScrollController,
//                     child: SizedBox(
//                       height: currentTotalHeight - 20.h,
//                       child: Stack(
//                         children: [
//                           // Hour lines with conditional color
//                           _buildDynamicHourLines(startHour, endHour, currentHourHeightMap, currentTasksByMinute),
//
//                           // Cards in chronological order
//                           ...allTasks.map((task) {
//                             final top = taskTops[task.id]!;
//                             return Positioned(
//                               top: top,
//                               left: 0,
//                               right: 16.w,
//                               child: _draggableCard(task: task),
//                             );
//                           }).toList(),
//
//                           // Live time preview
//                           if (_previewTime != null && _previewTop != null)
//                             Positioned(
//                               top: _previewTop! - 10.h,
//                               left: 16.w,
//                               child: Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                                 decoration: BoxDecoration(
//                                   color: Colors.black87,
//                                   borderRadius: BorderRadius.circular(8.r),
//                                 ),
//                                 child: Text(
//                                   _previewTime!,
//                                   style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   // ────── Helper: Get minute offset ──────
//   double _getMinuteOffset(int minuteOfDay, int startHour, Map<int, double> hourHeightMap) {
//     final h = minuteOfDay ~/ 60;
//     final m = minuteOfDay % 60;
//     double offset = 0.0;
//     for (int hour = startHour; hour < h; hour++) {
//       offset += hourHeightMap[hour]!;
//     }
//     final pixelsPerMinute = hourHeightMap[h]! / 60.0;
//     return offset + m * pixelsPerMinute;
//   }
//
//   // ────── Find closest minute ──────
//   int _getClosestMinute(double dy, int startHour, int endHour, Map<int, double> hourHeightMap) {
//     double cumulative = 0.0;
//     double minDist = double.infinity;
//     int closest = startHour * 60;
//
//     for (int h = startHour; h <= endHour; h++) {
//       final hourHeight = hourHeightMap[h]!;
//       final pixelsPerMinute = hourHeight / 60.0;
//
//       for (int m = 0; m < 60; m++) {
//         final minuteOffset = cumulative + m * pixelsPerMinute;
//         final dist = (minuteOffset - dy).abs();
//         if (dist < minDist) {
//           minDist = dist;
//           closest = h * 60 + m;
//         }
//       }
//       cumulative += hourHeight;
//     }
//     return closest.clamp(startHour * 60, endHour * 60 + 59);
//   }
//
//   // ────── DRAGGABLE CARD ──────
//   Widget _draggableCard({required Task task}) {
//     final bool faded = task.isCompleted || DateTime.now().isAfter(task.startTime.add(task.duration));
//
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Positioned(
//           left: -6.w,
//           top: 0,
//           child: Container(
//             width: 10.w,
//             height: 10.w,
//             decoration: BoxDecoration(
//                 color: task.isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
//                 shape: BoxShape.circle),
//           ),
//         ),
//         LongPressDraggable<Task>(
//           data: task,
//           feedback: Material(
//             color: Colors.transparent,
//             child: Opacity(
//               opacity: 0.9,
//               child: SizedBox(width: MediaQuery.of(context).size.width - 100.w, child: _cardContent(task, true)),
//             ),
//           ),
//           childWhenDragging: Opacity(opacity: 0.3, child: _cardContent(task, faded)),
//           onDragStarted: () {
//             _draggedTask = task;
//             _startAutoScroll();
//             setState(() {
//               _previewTime = null;
//               _previewTop = null;
//             });
//           },
//           onDragEnd: (_) {
//             _draggedTask = null;
//             _stopAutoScroll();
//             setState(() {
//               _previewTime = null;
//               _previewTop = null;
//             });
//           },
//           child: GestureDetector(
//             onTap: () => context.push('/task-details', extra: task),
//             child: Padding(padding: EdgeInsets.only(left: 5.w), child: _cardContent(task, faded)),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _cardContent(Task task, bool faded) {
//     return Opacity(
//       opacity: faded ? 0.4 : 1.0,
//       child: Container(
//         height: _cardHeight,
//         padding: EdgeInsets.all(8.w),
//         margin: EdgeInsets.only(bottom: 2.h),
//         decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: Colors.grey[200]!),
//             borderRadius: BorderRadius.circular(12.r)),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(DateFormat('h:mm a').format(task.startTime),
//                       style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.green[700], fontFamily: 'Poppins')),
//                   SizedBox(height: 4.h),
//                   Text(task.title,
//                       style: TextStyle(
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.bold,
//                           color: task.isCompleted ? Colors.grey[600] : Colors.black87,
//                           fontFamily: 'Poppins',
//                           decoration: task.isCompleted ? TextDecoration.lineThrough : null),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis),
//                   SizedBox(height: 4.h),
//                   Wrap(
//                       spacing: 8.w,
//                       runSpacing: 4.h,
//                       children: task.tags
//                           .map((tg) => Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                           decoration: BoxDecoration(color: tg.backgroundColor, borderRadius: BorderRadius.circular(6.r)),
//                           child: Text(tg.name,
//                               style: TextStyle(color: tg.textColor, fontSize: 11.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))))
//                           .toList()),
//                   SizedBox(height: 4.h),
//                   Row(children: [
//                     Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
//                     SizedBox(width: 2.w),
//                     Text(_formatDuration(task.duration),
//                         style: TextStyle(fontSize: 10.sp, color: Colors.grey[600], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
//                   ]),
//                 ],
//               ),
//             ),
//             GestureDetector(
//               onTap: () => Provider.of<TaskProvider>(context, listen: false).toggleTaskCompletion(task.id),
//               child: Container(
//                 width: 30.w,
//                 height: 26.w,
//                 decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: task.isCompleted ? Colors.grey[400]! : const Color(0xFF4CAF50), width: 2),
//                     color: task.isCompleted ? Colors.grey[400] : Colors.transparent),
//                 child: task.isCompleted ? Icon(Icons.check, size: 12.sp, color: Colors.white) : null,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
// // ────── HOUR LINES – Conditional Color (White if tasks exist) ──────
//   Widget _buildDynamicHourLines(int startHour, int endHour, Map<int, double> hourHeightMap, Map<int, List<Task>> tasksByMinute) {
//     double cumulative = 0.0;
//     return Stack(
//       children: List.generate(endHour - startHour + 1, (i) {
//         final hour = startHour + i;
//         final height = hourHeightMap[hour]!;
//         final top = cumulative;
//
//         // Check if this hour has any tasks
//         final minuteStart = hour * 60;
//         final hasTasks = tasksByMinute.entries.any((e) => e.key >= minuteStart && e.key < minuteStart + 60);
//
//         final lineColor = hasTasks ? Colors.white : Colors.grey[400];
//
//         cumulative += height;
//
//         return Positioned(
//           top: top,
//           left: 0,
//           right: 0,
//           child: Container(height: 1, color: lineColor),
//         );
//       }),
//     );
//   }
//   // ────── HEADER ──────
//   Widget _buildHeader() {
//     final now = DateTime.now();
//     final date = DateFormat('EEEE, MMMM d, y').format(now);
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SvgPicture.asset('assets/images/Saytask_logo.svg', height: 24.h, width: 100.w),
//               // Icon(Icons.settings_outlined, size: 24.sp, color: AppColors.black),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           Text('Today', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
//           SizedBox(height: 6.h),
//           Text(date, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
//           SizedBox(height: 10.h),
//           GestureDetector(
//             onTap: () => setState(() => _isCompactView = !_isCompactView),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(_isCompactView ? 'Expanded Schedule' : 'Compact View',
//                     style: TextStyle(fontSize: 14.sp, color: Colors.grey[800], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
//                 Icon(_isCompactView ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.grey[700]),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes % 60;
//     return h > 0 ? '$h hr${m > 0 ? ', $m min' : ''}' : '$m min';
//   }
//
//   // ────── AUTO-SCROLL ──────
//   void _startAutoScroll() async {
//     _autoScrolling = true;
//     while (_autoScrolling && _draggedTask != null) {
//       await Future.delayed(const Duration(milliseconds: 50));
//       if (!mounted || _pointerOffset == null) return;
//
//       final y = _pointerOffset!.dy;
//       final max = _scheduleScrollController.position.maxScrollExtent;
//       final cur = _scheduleScrollController.offset;
//       double delta = 0;
//
//       if (y < _scrollThreshold) {
//         delta = -_scrollSpeed * (1 - y / _scrollThreshold);
//       } else if (y > MediaQuery.of(context).size.height - _scrollThreshold) {
//         final dist = y - (MediaQuery.of(context).size.height - _scrollThreshold);
//         delta = _scrollSpeed * (1 + dist / _scrollThreshold);
//       }
//
//       final newOff = (cur + delta).clamp(0.0, max);
//       _scheduleScrollController.jumpTo(newOff);
//       _timelineScrollController.jumpTo(newOff);
//     }
//   }
//
//   void _stopAutoScroll() => _autoScrolling = false;
// }
//
