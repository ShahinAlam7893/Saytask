// lib/view/today/today_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/utils/utils.dart';
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

  dynamic _draggedItem;
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
      final cp = Provider.of<CalendarProvider>(context, listen: false);
      await Future.wait([tp.loadTasks(), cp.loadEvents()]);
      _autoCheckPastTasks(tp.tasks);
    });
  }

  void _autoCheckPastTasks(List<Task> tasks) {
    final now = DateTime.now();
    for (final task in tasks) {
      final endTime = task.startTime.add(task.duration);
      if (endTime.isBefore(now) && !task.isCompleted) {
        Provider.of<TaskProvider>(
          context,
          listen: false,
        ).toggleTaskCompletion(task.id);
      }
    }
  }

  void _syncScrollControllers() {
    _scheduleScrollController.addListener(() {
      if (_timelineScrollController.offset !=
          _scheduleScrollController.offset) {
        _timelineScrollController.jumpTo(_scheduleScrollController.offset);
      }
    });
    _timelineScrollController.addListener(() {
      if (_scheduleScrollController.offset !=
          _timelineScrollController.offset) {
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

  bool _isCompleted(dynamic item) {
    if (item is Task) return item.isCompleted;
    if (item is Event) return item.isCompleted;
    return false;
  }

  bool _isFaded(dynamic item) => _isCompleted(item);
  bool _hasStrikethrough(dynamic item) => _isCompleted(item);

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, CalendarProvider>(
      builder: (context, tp, cp, _) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        final List<dynamic> todayItems = [];

        todayItems.addAll(
          tp.tasks.where((t) {
            final taskDate = DateTime(
              t.startTime.year,
              t.startTime.month,
              t.startTime.day,
            );
            return taskDate == todayDate;
          }),
        );

        todayItems.addAll(cp.allEvents.where((e) => isToday(e.eventDateTime)));

        todayItems.sort((a, b) => getStartTime(a).compareTo(getStartTime(b)));

        int startHour = 6;
        int endHour = 23;

        if (todayItems.isNotEmpty) {
          final earliest = getStartTime(todayItems.first).hour;
          final latest = getStartTime(todayItems.last).hour + 1;
          startHour = earliest.clamp(0, 6);
          endHour = latest.clamp(18, 23);
        }

        return _isCompactView
            ? _buildCompactView(todayItems)
            : _buildExpandedView(todayItems, startHour, endHour);
      },
    );
  }

  // ======================== COMPACT VIEW ========================
  Widget _buildCompactView(List<dynamic> todayItems) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            todayItems.isEmpty
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "No tasks or events today",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      controller: _mainScrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: todayItems.length,
                      itemBuilder: (_, i) =>
                          _buildUnifiedCompactItem(todayItems[i]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedCompactItem(dynamic item) {
    final isTask = item is Task;
    final isCompleted = _isCompleted(item);
    final isFaded = _isFaded(item);
    final hasStrikethrough = _hasStrikethrough(item);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.w,
            child: Text(
              DateFormat('h a').format(getStartTime(item)),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.black,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 6.h),
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey[400]
                      : const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isTask) {
                  context.push('/task-details/${item.id}');
                } else {
                  context.push('/event_details', extra: item);
                }
              },
              child: _buildUnifiedCompactCard(item, isFaded, hasStrikethrough),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedCompactCard(
    dynamic item,
    bool faded,
    bool strikethrough,
  ) {
    final isTask = item is Task;

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
                    getTitle(item),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: strikethrough ? Colors.grey[600] : Colors.black87,
                      fontFamily: 'Poppins',
                      decoration: strikethrough
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  if (isTask && item.tags.isNotEmpty)
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: item.tags
                          .map(
                            (tg) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
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
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (!isTask && item.locationAddress.isNotEmpty)
                    Text(
                      item.locationAddress,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isTask ? _formatDuration(item.duration) : '1 hr',
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
            _buildCheckbox(
              isChecked: _isCompleted(item),
              onTap: isTask
                  ? () => context.read<TaskProvider>().toggleTaskCompletion(
                      item.id,
                    )
                  : () {},
              size: 30.w,
              iconSize: 26.sp,
            ),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }

  // ======================== EXPANDED VIEW ========================
  Widget _buildExpandedView(
    List<dynamic> todayItems,
    int startHour,
    int endHour,
  ) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _mainScrollController,
          child: Column(
            children: [
              _buildHeader(),
              Consumer2<TaskProvider, CalendarProvider>(
                builder: (context, tp, cp, _) {
                  final layout = _computeTimelineLayout(
                    todayItems,
                    startHour,
                    endHour,
                  );
                  final hourHeightMap =
                      layout['hourHeightMap'] as Map<int, double>;
                  final minuteToOffset =
                      layout['minuteToOffset'] as Map<int, double>;
                  final totalHeight = layout['totalHeight'] as double;

                  return SizedBox(
                    height: totalHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDynamicTimeline(
                          startHour,
                          endHour,
                          hourHeightMap,
                        ),
                        _buildScrollableDivider(
                          startHour,
                          endHour,
                          hourHeightMap,
                        ),
                        Expanded(
                          child: _buildScheduleArea(
                            allItems: todayItems,
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

  Map<String, dynamic> _computeTimelineLayout(
    List<dynamic> items,
    int startHour,
    int endHour,
  ) {
    final hourTaskCount = <int, int>{};
    for (final item in items) {
      final h = getStartTime(item).hour;
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

  Widget _buildDynamicTimeline(
    int startHour,
    int endHour,
    Map<int, double> hourHeightMap,
  ) {
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
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScrollableDivider(
    int startHour,
    int endHour,
    Map<int, double> hourHeightMap,
  ) {
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

  Widget _buildScheduleArea({
    required List<dynamic> allItems,
    required Map<int, double> hourHeightMap,
    required Map<int, double> minuteToOffset,
    required double totalHeight,
    required TaskProvider taskProvider,
  }) {
    final itemTops = <String, double>{};
    int slotIndex = 0;
    int lastHour = -1;

    for (final item in allItems) {
      final hour = getStartTime(item).hour;
      if (hour != lastHour) {
        slotIndex = 0;
        lastHour = hour;
      }
      final base = minuteToOffset[hour * 60] ?? 0.0;
      final id = item is Task ? item.id : 'event_${item.id}';
      itemTops[id] = base + slotIndex * (_cardHeight + _cardGap);
      slotIndex++;
    }

    return DragTarget<Object>(
      key: _scheduleAreaKey,
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _handleDrop(
        details,
        hourHeightMap,
        taskProvider,
        context.read<CalendarProvider>(),
      ),

      builder: (context, _, __) {
        return Listener(
          onPointerMove: (e) => _handlePointerMove(e, hourHeightMap),
          child: SingleChildScrollView(
            controller: _scheduleScrollController,
            child: SizedBox(
              height: totalHeight - 20.h,
              child: Stack(
                children: [
                  _buildDynamicHourLines(
                    hourHeightMap.keys.first,
                    hourHeightMap.keys.last,
                    hourHeightMap,
                    allItems,
                  ),
                  ...allItems.map((item) {
                    final id = item is Task ? item.id : 'event_${item.id}';
                    final top = itemTops[id]!;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 16.w,
                      child: _buildUnifiedDraggableCard(item),
                    );
                  }),
                  if (_previewTime != null && _previewTop != null)
                    Positioned(
                      top: _previewTop! - 10.h,
                      left: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _previewTime!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildUnifiedDraggableCard(dynamic item) {
    final isTask = item is Task;
    final isCompleted = _isCompleted(item);
    final isFaded = _isFaded(item);
    final hasStrikethrough = _hasStrikethrough(item);

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
              color: isCompleted ? Colors.grey[400] : const Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
        ),
        LongPressDraggable<Object>(
          data: item,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 100.w,
                child: _buildCardContent(item, true, true),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildCardContent(item, isFaded, hasStrikethrough),
          ),
          onDragStarted: () {
            _draggedItem = item;
            _startAutoScroll();
            setState(() => _previewTime = _previewTop = null);
          },
          onDragEnd: (_) {
            _draggedItem = null;
            _stopAutoScroll();
            setState(() => _previewTime = _previewTop = null);
          },
          child: GestureDetector(
            onTap: () {
              if (isTask) {
                context.push('/task-details/${item.id}');
              } else {
                context.push('/event_details', extra: item);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(left: 5.w),
              child: _buildCardContent(item, isFaded, hasStrikethrough),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(dynamic item, bool faded, bool strikethrough) {
    final isTask = item is Task;

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
                    DateFormat('h:mm a').format(getStartTime(item)),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    getTitle(item),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: strikethrough ? Colors.grey[600] : Colors.black87,
                      fontFamily: 'Poppins',
                      decoration: strikethrough
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  if (isTask && item.tags.isNotEmpty)
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: item.tags
                          .map(
                            (tg) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
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
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (!isTask && item.locationAddress.isNotEmpty)
                    Text(
                      item.locationAddress,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        isTask ? _formatDuration(item.duration) : '1 hr',
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
            _buildCheckbox(
              isChecked: _isCompleted(item),
              onTap: () {
                if (item is Task) {
                  context.read<TaskProvider>().toggleTaskCompletion(item.id);
                } else if (item is Event) {
                  context.read<CalendarProvider>().toggleEventCompletion(
                    item.id,
                  );
                }
              },
              size: 30.w,
              iconSize: 26.sp,
            ),
          ],
        ),
      ),
    );
  }

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
              width: 2,
            ),
            color: isChecked ? Colors.grey[400] : Colors.transparent,
          ),
          child: isChecked
              ? Icon(Icons.check, size: iconSize, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildDynamicHourLines(
    int startHour,
    int endHour,
    Map<int, double> hourHeightMap,
    List<dynamic> items,
  ) {
    double cumulative = 0.0;
    return Stack(
      children: List.generate(endHour - startHour + 1, (i) {
        final hour = startHour + i;
        final height = hourHeightMap[hour]!;
        final hasItems = items.any((item) => getStartTime(item).hour == hour);
        final color = hasItems ? Colors.white : Colors.grey[400];
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
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            date,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
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

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '$h hr${m > 0 ? ', $m min' : ''}' : '$m min';
  }

  void _handlePointerMove(PointerMoveEvent e, Map<int, double> hourHeightMap) {
    if (_draggedItem == null) return;
    _pointerOffset = e.position;

    final renderBox =
        _scheduleAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(e.position);
    final dy = localPos.dy + _scheduleScrollController.offset;

    final closestMinute = _getClosestMinute(
      dy,
      hourHeightMap.keys.first,
      hourHeightMap.keys.last,
      hourHeightMap,
    );
    final hour = closestMinute ~/ 60;
    final minute = closestMinute % 60;
    final time = DateTime(2020, 1, 1, hour, minute);

    setState(() {
      _previewTime = DateFormat('h:mm a').format(time);
      _previewTop = _getMinuteOffset(
        closestMinute,
        hourHeightMap.keys.first,
        hourHeightMap,
      );
    });
  }

  void _handleDrop(
    DragTargetDetails<dynamic> details,
    Map<int, double> hourHeightMap,
    TaskProvider tp,
    CalendarProvider cp,
  ) {
    final renderBox =
        _scheduleAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Convert global drop position → local scroll position
    final localOffset = renderBox.globalToLocal(details.offset);
    final dy = localOffset.dy + _scheduleScrollController.offset;

    // Find nearest minute slot
    final closestMinute = _getClosestMinute(
      dy,
      hourHeightMap.keys.first,
      hourHeightMap.keys.last,
      hourHeightMap,
    );

    final hour = closestMinute ~/ 60;
    final minute = closestMinute % 60;

    final today = DateTime.now();
    final newStart = DateTime(today.year, today.month, today.day, hour, minute);

    // ─────────────── UPDATE TASK ───────────────
    if (details.data is Task) {
      final task = details.data as Task;
      tp.updateTaskTime(task.id, newStart);
    }
    // ─────────────── UPDATE EVENT ───────────────
    else if (details.data is Event) {
      final event = details.data as Event;
      cp.updateEventTime(event.id, newStart);
    }

    // Reset preview UI
    setState(() {
      _previewTime = null;
      _previewTop = null;
    });
  }

  double _getMinuteOffset(
    int minuteOfDay,
    int startHour,
    Map<int, double> hourHeightMap,
  ) {
    final h = minuteOfDay ~/ 60;
    double offset = 0.0;
    for (int hour = startHour; hour < h; hour++) {
      offset += hourHeightMap[hour]!;
    }
    final pixelsPerMinute = hourHeightMap[h]! / 60.0;
    return offset + (minuteOfDay % 60) * pixelsPerMinute;
  }

  int _getClosestMinute(
    double dy,
    int startHour,
    int endHour,
    Map<int, double> hourHeightMap,
  ) {
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
              color: task.isCompleted
                  ? Colors.grey[400]
                  : const Color(0xFF4CAF50),
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
                child: _buildCardContent(task, true, true),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildCardContent(task, isFaded, hasStrikethrough),
          ),
          onDragStarted: () {
            _draggedItem = task;
            _startAutoScroll();
            setState(() => _previewTime = _previewTop = null);
          },
          onDragEnd: (_) {
            _draggedItem = null;
            _stopAutoScroll();
            setState(() => _previewTime = _previewTop = null);
          },
          child: GestureDetector(
            onTap: () => context.push('/task-details/${task.id}'),
            child: Padding(
              padding: EdgeInsets.only(left: 5.w),
              child: _buildCardContent(task, isFaded, hasStrikethrough),
            ),
          ),
        ),
      ],
    );
  }

  void _startAutoScroll() async {
    _autoScrolling = true;
    final renderBox =
        _scheduleAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    while (_autoScrolling && _draggedItem != null && mounted) {
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
