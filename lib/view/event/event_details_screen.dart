import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/calendar_service.dart';
import '../../model/event_model.dart';
import '../../res/color.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event? event; // Nullable, used as a fallback or for initial navigation

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        // If event is null, show "No event found"
        if (event == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                "No event found.",
                style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.black),
              ),
            ),
          );
        }

        // Find the event in the provider using the ID
        final dateKey = DateTime.utc(event!.date.year, event!.date.month, event!.date.day);
        // Use the public selectedDayEvents or getEventsForDate
        final events = provider.selectedDayEvents.isNotEmpty &&
            DateUtils.isSameDay(provider.selectedDate, dateKey)
            ? provider.selectedDayEvents
            : provider.getEventsForDate(dateKey);
        final currentEvent = events.firstWhere(
              (e) => e.id == event!.id,
          orElse: () => event!, // Fallback to passed event if not found
        );

        return Scaffold(
          backgroundColor: Colors.white,
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
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_outlined, size: 20.sp, color: Colors.black),
                      onPressed: context.pop,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF6E0),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      currentEvent.title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Description:",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  currentEvent.description.isNotEmpty
                      ? currentEvent.description
                      : "No description added.",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('MMMM d, yyyy').format(currentEvent.date),
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text(
                      currentEvent.time.format(context),
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text(
                      currentEvent.location.isNotEmpty
                          ? currentEvent.location
                          : "No location specified",
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.notifications, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text(
                      currentEvent.reminderMinutes != 0
                          ? 'Reminder ${currentEvent.reminderMinutes} minute before'
                          : 'No reminder set',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed('editEvent', extra: currentEvent);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'Edit Event',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}