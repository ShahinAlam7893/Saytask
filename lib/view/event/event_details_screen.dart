// lib/view/event/event_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/event_model.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/res/color.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event? event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
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

        Event? currentEvent;
        try {
          currentEvent = provider.allEvents.firstWhere(
            (e) => e.id == event!.id,
            orElse: () => event!,
          );
        } catch (e) {
          currentEvent = event;
        }
        final DateTime displayDate = currentEvent?.eventDateTime ?? DateTime.now();
        final String formattedDate = DateFormat('MMMM d, yyyy').format(displayDate);
        final String formattedTime = DateFormat('h:mm a').format(displayDate);

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
                  onPressed: () => context.push('/settings'),
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
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Title Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF6E0),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      currentEvent!.title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                Text(
                  "Description:",
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  currentEvent.description.isNotEmpty
                      ? currentEvent.description
                      : "No description added.",
                  style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF4B5563)),
                ),
                SizedBox(height: 16.h),

                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        currentEvent.locationAddress.isNotEmpty
                            ? currentEvent.locationAddress
                            : "No location specified",
                        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Reminder + Call Me (updated with natural text)
                Row(
                  children: [
                    Icon(Icons.notifications, size: 18.sp, color: Colors.black),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _formatReminderText(currentEvent.reminderMinutes),
                        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black),
                      ),
                    ),
                    if (currentEvent.callMe)
                      Row(
                        children: [
                          SizedBox(width: 12.w),
                          Icon(Icons.call, size: 18.sp, color: AppColors.green),
                          SizedBox(width: 4.w),
                          Text(
                            "Call Me",
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: 30.h),

                // Edit Button
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
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatReminderText(int minutes) {
    if (minutes <= 0) return "No reminder set";

    switch (minutes) {
      case 5:
        return "5 minutes before";
      case 10:
        return "10 minutes before";
      case 15:
        return "15 minutes before";
      case 30:
        return "30 minutes before";
      case 60:
        return "1 hour before";
      case 120:
        return "2 hours before";
      default:
        return "$minutes minutes before";
    }
  }
}