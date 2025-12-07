// lib/view/today/today_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/res/color.dart';
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

  static const double _cardHeight = 120.0;
  static const double _cardGap = 5.0;
  static const double _emptyHourHeight = 120.0;

  bool _isCompactView = false;

  Task? _draggedTask;
  bool _autoScrolling = false;
  static const _scrollThreshold = 80.0;
  static const _scrollSpeed = 10.0;
  Offset? _pointerOffset;
  final GlobalKey _scheduleAreaKey = GlobalKey();

  String? _previewTime;
  double? _previewTop;

  @override
  void initState() {
    super.initState();
    _syncScrollControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tp = Provider.of<TaskProvider>(context, listen: false);
      await tp.loadTasks();
      _autoCheckPastTasks(tp.tasks);
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
    _mainScrollController.dispose();
    _scheduleScrollController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  bool _isFaded(Task t) => t.isCompleted;
  bool _hasStrikethrough(Task t) => t.isCompleted;

  @override
Widget build(BuildContext context) {
  return Consumer<TaskProvider>(
    builder: (context, tp, _) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final todayTasks = tp.tasks.where((t) {
        final taskDate = DateTime(t.startTime.year, t.startTime.month, t.startTime.day);
        return taskDate == todayDate;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      int startHour = 6;
      int endHour = 23;

      if (todayTasks.isNotEmpty) {
        final earliest = todayTasks.first.startTime.hour;
        final latest = todayTasks.last.startTime.hour;

        startHour = earliest.clamp(0, 6);
        endHour = latest >= 23 ? 23 : 23;
      }

      return _isCompactView
          ? _buildCompactView(todayTasks)
          : _buildExpandedView(todayTasks, startHour, endHour);
    },
  );
}

  // ──────────────────────────────────────────────────────────────
  // COMPACT VIEW
  // ──────────────────────────────────────────────────────────────
  Widget _buildCompactView(List<Task> todayTasks) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            todayTasks.isEmpty
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64.sp, color: Colors.grey[400]),
                          SizedBox(height: 16.h),
                          Text("No tasks today", style: TextStyle(fontSize: 16.sp, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      controller: _mainScrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: todayTasks.length,
                      itemBuilder: (_, i) => _buildCompactTaskItem(todayTasks[i]),
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
              onTap: () => context.push('/task-details/${t.id}'),
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
                    children: t.tags.map((tg) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(color: tg.backgroundColor, borderRadius: BorderRadius.circular(6.r)),
                      child: Text(tg.name, style: TextStyle(color: tg.textColor, fontSize: 11.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    )).toList(),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Text(_formatDuration(t.duration), style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
            _buildCheckbox(
              isChecked: t.isCompleted,
              onTap: () => context.read<TaskProvider>().toggleTaskCompletion(t.id),
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
  // EXPANDED VIEW — DYNAMIC TIMELINE
  // ──────────────────────────────────────────────────────────────
  Widget _buildExpandedView(List<Task> todayTasks, int startHour, int endHour) {
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
                final layout = _computeTimelineLayout(todayTasks, startHour, endHour);
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
                          allTasks: todayTasks,
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
  Map<String, dynamic> _computeTimelineLayout(List<Task> tasks, int startHour, int endHour) {
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
      hourHeightMap[h] = cnt > 0 ? cnt * (_cardHeight + _cardGap) : _emptyHourHeight;
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
                    DateFormat('h a').format(DateTime(2020, 1, 1, hour)),
                    style: TextStyle(fontSize: 12.sp, color: AppColors.black, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
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
      onAcceptWithDetails: (details) => _handleDrop(details, startHour, endHour, hourHeightMap, taskProvider, _scheduleAreaKey),
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
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8.r)),
                        child: Text(_previewTime!, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
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

  void _handlePointerMove(PointerMoveEvent e, int startHour, int endHour, Map<int, double> hourHeightMap) {
    if (_draggedTask == null) return;
    _pointerOffset = e.position;

    final renderBox = _scheduleAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(e.position);
    final dy = localPos.dy + _scheduleScrollController.offset;

    final closestMinute = _getClosestMinute(dy, startHour, endHour, hourHeightMap);
    final hour = closestMinute ~/ 60;
    final minute = closestMinute % 60;
    final time = DateTime(2020, 1, 1, hour, minute);

    setState(() {
      _previewTime = DateFormat('h:mm a').format(time);
      _previewTop = _getMinuteOffset(closestMinute, startHour, hourHeightMap);
    });
  }

  void _handleDrop(DragTargetDetails<Task> details, int startHour, int endHour, Map<int, double> hourHeightMap, TaskProvider tp, GlobalKey scheduleKey) {
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

    final shouldBeCompleted = newEnd.isBefore(DateTime.now());
    if (details.data.isCompleted != shouldBeCompleted) {
      tp.toggleTaskCompletion(details.data.id);
    }

    tp.updateTaskTime(details.data.id, newStart);

    setState(() {
      _previewTime = null;
      _previewTop = null;
    });
  }

  double _getMinuteOffset(int minuteOfDay, int startHour, Map<int, double> hourHeightMap) {
    final h = minuteOfDay ~/ 60;
    double offset = 0.0;
    for (int hour = startHour; hour < h; hour++) {
      offset += hourHeightMap[hour]!;
    }
    final pixelsPerMinute = hourHeightMap[h]! / 60.0;
    return offset + (minuteOfDay % 60) * pixelsPerMinute;
  }

  int _getClosestMinute(double dy, int startHour, int endHour, Map<int, double> hourHeightMap) {
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
              child: SizedBox(width: MediaQuery.of(context).size.width - 100.w, child: _buildCardContent(task, true, true)),
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
            onTap: () => context.push('/task-details/${task.id}'),
            child: Padding(padding: EdgeInsets.only(left: 5.w), child: _buildCardContent(task, isFaded, hasStrikethrough)),
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
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.green[700], fontFamily: 'Poppins'),
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
                    children: task.tags.map((tg) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(color: tg.backgroundColor, borderRadius: BorderRadius.circular(6.r)),
                      child: Text(tg.name, style: TextStyle(color: tg.textColor, fontSize: 11.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    )).toList(),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                      SizedBox(width: 2.w),
                      Text(_formatDuration(task.duration), style: TextStyle(fontSize: 10.sp, color: Colors.grey[600], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
            _buildCheckbox(
              isChecked: task.isCompleted,
              onTap: () => context.read<TaskProvider>().toggleTaskCompletion(task.id),
              size: 30.w,
              iconSize: 26.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({required bool isChecked, required VoidCallback onTap, required double size, required double iconSize}) {
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
            border: Border.all(color: isChecked ? Colors.grey[400]! : const Color(0xFF4CAF50), width: 2),
            color: isChecked ? Colors.grey[400] : Colors.transparent,
          ),
          child: isChecked ? Icon(Icons.check, size: iconSize, color: Colors.white) : null,
        ),
      ),
    );
  }

  Widget _buildDynamicHourLines(int startHour, int endHour, Map<int, double> hourHeightMap, List<Task> tasks) {
    double cumulative = 0.0;
    return Stack(
      children: List.generate(endHour - startHour + 1, (i) {
        final hour = startHour + i;
        final height = hourHeightMap[hour]!;
        final hasTasks = tasks.any((t) => t.startTime.hour == hour);
        final color = hasTasks ? Colors.white : Colors.grey[400];
        final top = cumulative;
        cumulative += height;
        return Positioned(top: top, left: 0, right: 0, child: Container(height: 1, color: color));
      }),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final date = DateFormat('EEEE, MMMM d, y').format(now);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SvgPicture.asset('assets/images/Saytask_logo.svg', height: 24.h, width: 100.w),
          ]),
          SizedBox(height: 16.h),
          Text('Today', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          SizedBox(height: 6.h),
          Text(date, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => setState(() => _isCompactView = !_isCompactView),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isCompactView ? 'Expanded Schedule' : 'Compact View', style: TextStyle(fontSize: 14.sp, color: Colors.grey[800], fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                Icon(_isCompactView ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.grey[700]),
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