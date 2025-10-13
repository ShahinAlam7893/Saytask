// screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/res/color.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // *** ADD initState ***
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      provider.setInitialDate(DateTime(2025, 10, 8));
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
            // Logo
            SvgPicture.asset(
              'assets/images/Saytask_logo.svg',
              height: 24.h,
              width: 100.w,
            ),
            // Settings Icon
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Colors.black,
                size: 24.sp,
              ),
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            const CalendarHeader(),
            SizedBox(height: 20.h),
            const WeekdayHeaders(),
            const CalendarGrid(),
            SizedBox(height: 16.h),
            const EventListHeader(),
            const Expanded(child: EventList()),
          ],
        ),
      ),
    );
  }
}

class EventList extends StatelessWidget {
  const EventList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final events = provider.selectedDayEvents;
        if (events.isEmpty) {
          return const Center(child: Text("No events for this day."));
        }
        return ListView.builder(
          padding: EdgeInsets.only(top: 10.h),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(event: event);
          },
        );
      },
    );
  }
}
// 1. Calendar Header (Month Selector)
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
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
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


// 2. Weekday Headers (S, M, T, W, T, F, S)
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


// 3. Calendar Grid
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final focusedDate = provider.focusedDate;
        final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
        final daysInMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0).day;

        // Calculate the weekday of the first day (Sunday is 7, we want it to be 0)
        int startingWeekday = firstDayOfMonth.weekday % 7;

        final daysToDisplay = <DateTime>[];

        // Days from previous month
        for (int i = 0; i < startingWeekday; i++) {
          daysToDisplay.add(firstDayOfMonth.subtract(Duration(days: startingWeekday - i)));
        }

        // Days of the current month
        for (int i = 0; i < daysInMonth; i++) {
          daysToDisplay.add(firstDayOfMonth.add(Duration(days: i)));
        }

        // Days from next month to fill the grid (total 42 cells for 6 weeks)
        final remainingCells = 42 - daysToDisplay.length;
        final lastDayOfMonth = DateTime(focusedDate.year, focusedDate.month, daysInMonth);
        for (int i = 0; i < remainingCells; i++) {
          daysToDisplay.add(lastDayOfMonth.add(Duration(days: i + 1)));
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: daysToDisplay.length,
          itemBuilder: (context, index) {
            final day = daysToDisplay[index];
            return DayTile(
              day: day,
              isCurrentMonth: day.month == focusedDate.month,
            );
          },
        );
      },
    );
  }
}

// 4. Day Tile (Each date cell)
class DayTile extends StatelessWidget {
  final DateTime day;
  final bool isCurrentMonth;

  const DayTile({
    super.key,
    required this.day,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isSelected = DateUtils.isSameDay(provider.selectedDate, day);
    final hasEvents = provider.hasEvents(day);

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

// 5. Event List Header (Below calendar)
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
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {context.push('/home');},
              icon: const Icon(
                Icons.add,
                size: 18,
                color: Colors.black, // make icon black
              ),
              label: Text(
                'Add Event',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.black, // make text black
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: const BorderSide(color: Colors.black, width: 1), // border color & width
                ),
                elevation: 0, // remove shadow for a flat look (optional)
              ),
            ),
          ],
        );
      },
    );
  }
}

// 6. Event Card
class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/event_details', extra: event);
        SnackBar(content: Text('${event.title} clicked!'));
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
              event.title,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14.sp, color: AppColors.deepBlack),
                    SizedBox(width: 4.w),
                    Text(
                      event.location,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.deepBlack),
                    ),
                  ],
                ),
                SizedBox(height: 5.h,),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14.sp, color: AppColors.deepBlack),
                    SizedBox(width: 4.w),
                    Text(
                      event.time.format(context),
                      style: GoogleFonts.inter(fontSize: 12.sp, color: AppColors.deepBlack),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
