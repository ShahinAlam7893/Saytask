import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:saytask/res/components/common_button.dart';
import '../../model/event_model.dart';
import '../../res/color.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event? event; // nullable

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
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

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w,),
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
                  event!.title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Description
            Text(
              "Description:",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              event!.description.isNotEmpty
                  ? event!.description
                  : "No description added.",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF4B5563),
              ),
            ),
            SizedBox(height: 16.h),

            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18.sp, color: Colors.black),
                SizedBox(width: 8.w),
                Text(
                  DateFormat('MMMM d, yyyy').format(event!.date),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
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
                  event!.time.format(context),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Location
            Row(
              children: [
                Icon(Icons.location_on, size: 18.sp, color: Colors.black),
                SizedBox(width: 8.w),
                Text(
                  event!.location,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Reminder
            Row(
              children: [
                Icon(Icons.notifications, size: 18.sp, color: Colors.black),
                SizedBox(width: 8.w),
                Text(
                  'Reminder ${event!.reminderMinutes} minute before',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),

            // Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Edit page
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
  }
}
