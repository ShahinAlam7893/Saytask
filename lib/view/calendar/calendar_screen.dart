// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/model/today_task_model.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/res/color.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().loadEvents();
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70.h,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/images/Saytask_logo.svg',
              height: 24.h,
              width: 100.w,
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: Colors.black, size: 24.sp),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CalendarHeader(),
                SizedBox(height: 20.h),
                const WeekdayHeaders(),
                const CalendarGrid(),
                SizedBox(height: 16.h),
                const EventListHeader(),
                SizedBox(height: 8.h),
                Consumer<CalendarProvider>(
                  builder: (context, provider, child) {
                    final items = provider.selectedDayItems;
                    if (items.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.only(top: 10.h, bottom: 30.h),
                        child: const Center(child: Text("No events or tasks for this day.")),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.only(top: 10.h, bottom: 30.h),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return UnifiedCalendarCard(item: item);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// === All your existing widgets unchanged (CalendarHeader, WeekdayHeaders, CalendarGrid, DayTile, EventListHeader) ===
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: provider.previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(provider.focusedDate),
                style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: provider.nextMonth,
              ),
            ],
          ),
        );
      },
    );
  }
}

class WeekdayHeaders extends StatelessWidget {
  const WeekdayHeaders({super.key});

  @override
  Widget build(BuildContext context) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) => Text(
        day,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6B7280),
        ),
      )).toList(),
    );
  }
}

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final focusedDate = provider.focusedDate;
        final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
        final daysInMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0).day;
        int startingWeekday = firstDayOfMonth.weekday % 7;

        final daysToDisplay = <DateTime?>[];
        for (int i = 0; i < startingWeekday; i++) daysToDisplay.add(null);
        for (int i = 1; i <= daysInMonth; i++) {
          daysToDisplay.add(DateTime(focusedDate.year, focusedDate.month, i));
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: daysToDisplay.length,
          itemBuilder: (context, index) {
            final day = daysToDisplay[index];
            if (day == null) return const SizedBox.shrink();
            return DayTile(day: day, isCurrentMonth: true);
          },
        );
      },
    );
  }
}

class DayTile extends StatelessWidget {
  final DateTime day;
  final bool isCurrentMonth;

  const DayTile({super.key, required this.day, required this.isCurrentMonth});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isSelected = DateUtils.isSameDay(provider.selectedDate, day);
    final hasEvents = provider.hasItems(day);

    return GestureDetector(
      onTap: () => provider.selectDate(day),
      child: Container(
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.blue : const Color(0xFFD2D2D2),
            width: 1.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
                color: isCurrentMonth ? const Color(0xFF1F1F1F) : Colors.grey,
              ),
            ),
            if (hasEvents)
              Container(
                width: 6.w,
                height: 6.h,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EventListHeader extends StatelessWidget {
  const EventListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy, MMMM d').format(provider.selectedDate),
              style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => context.push('/home'),
              icon: const Icon(Icons.add, size: 18, color: Colors.black),
              label: Text('Add Event', style: TextStyle(fontFamily: 'Inter', color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: const BorderSide(color: Colors.black, width: 1),
                ),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

// === Unified Card — Exact same design for Task & Event (no tags for Task) ===
class UnifiedCalendarCard extends StatelessWidget {
  final dynamic item;

  const UnifiedCalendarCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isTask = item is Task;
    final isEvent = item is Event;

    final DateTime? eventDateTime = isTask ? item.startTime : item.eventDateTime;
    if (eventDateTime == null) return const SizedBox.shrink();

    final timeText = TimeOfDay.fromDateTime(eventDateTime).format(context);

    return InkWell(
      onTap: () {
        if (isEvent) {
          context.push('/event_details', extra: item);
        } else if (isTask) {
          context.push('/task-details/${item.id}');
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0x45AABCAF)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            SizedBox(height: 8.h),
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14.sp, color: AppColors.deepBlack),
                    SizedBox(width: 4.w),
                    Text(
                      timeText,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.deepBlack),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                if (isEvent)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14.sp, color: AppColors.deepBlack),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          item.locationAddress.isNotEmpty ? item.locationAddress : 'No location specified',
                          style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.deepBlack),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (isTask)
                  Text(
                    'No location specified',
                    style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.deepBlack.withOpacity(0.6)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}