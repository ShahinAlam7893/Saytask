// lib/res/components/schedule_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:saytask/model/today_task_model.dart';

class ScheduleCard extends StatelessWidget {
  final Task task;
  final double hourHeight;

  const ScheduleCard({
    super.key,
    required this.task,
    required this.hourHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Every card height = one hour slot
    final double cardHeight = hourHeight;

    return Container(
      height: cardHeight,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('h:mm a').format(task.startTime),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2.0),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: task.tags.map((tag) => _TagChip(tag: tag)).toList(),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 14.sp,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4.w),
              Text(
                _formatDuration(task.duration),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
}


class _TagChip extends StatelessWidget {
  final Tag tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: tag.backgroundColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          color: tag.textColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final String reminder;
  const _ReminderChip({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        reminder,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}