// lib/res/components/event_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saytask/res/color.dart';

class SpeackEventCard extends StatefulWidget {
  final String eventTitle;
  final String note;
  final String initialReminder;
  final bool initialCallMe;
  final VoidCallback? onSave;

  const SpeackEventCard({
    super.key,
    required this.eventTitle,
    required this.note,
    this.initialReminder = "At time of event",
    this.initialCallMe = false,
    this.onSave,
  });

  @override
  State<SpeackEventCard> createState() => _SpeackEventCardState();
}

class _SpeackEventCardState extends State<SpeackEventCard> {
  final ValueNotifier<bool> _switchController = ValueNotifier<bool>(false);
  bool isExpanded = false;
  late String selectedReminder;

  @override
  void initState() {
    super.initState();
    selectedReminder = widget.initialReminder;
    _switchController.value = widget.initialCallMe;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.secondaryTextColor,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title Row ---
            Row(
              children: [
                Container(width: 4.w, height: 16.h, color: Colors.green),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.eventTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ],
            ),
            SizedBox(height: 4.h),

            // --- Date Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tomorrow",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "All-day",
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // --- Call Me Switch ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.call, color: Colors.white70, size: 18.sp),
                    SizedBox(width: 10.w),
                    Text(
                      "Call Me",
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ],
                ),
                SizedBox(
                  width: 60.w,
                  height: 30.h,
                  child: AdvancedSwitch(
                    controller: _switchController,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),

            // --- Notification Dropdown ---
            Row(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: Colors.white70,
                  size: 18.sp,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedReminder,
                            dropdownColor: Colors.grey[850],
                            icon: const SizedBox.shrink(),
                            items:
                                [
                                  "At time of event",
                                  "5 minutes before",
                                  "10 minutes before",
                                  "15 minutes before",
                                  "30 minutes before",
                                  "1 hour before",
                                  "2 hours before",
                                  "13:00, 1 day before",
                                  "None",
                                ].map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        if (e == selectedReminder)
                                          const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedReminder = val);
                              }
                            },
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                          size: 26.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // --- Note Row ---
            Row(
              children: [
                Icon(
                  Icons.note_add_rounded,
                  color: Colors.white70,
                  size: 18.sp,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    widget.note,
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // --- Expanded Section ---
            if (isExpanded) ...[
              SizedBox(height: 12.h),
              // Fixed: Wrap buttons in Wrap widget to prevent overflow
              Center(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildMiniButton("Delay +1 hr", Icons.access_time),
                    _buildMiniButton("Call Me", Icons.call),
                    _buildMiniButton(
                      "Remind 30 min",
                      Icons.notifications_active,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.white,
                      size: 22.sp,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.edit, color: AppColors.white, size: 22.sp),
                  ),
                ],
              ),
            ],
            Center(
              child: SizedBox(
                height: 40.h,
                width: 120.w,
                child: ElevatedButton(
                  onPressed: widget.onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 6,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    minimumSize: Size(100.w, 40.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14.sp, color: Colors.white),
      label: Text(
        text,
        style: TextStyle(fontSize: 11.sp, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(0, 32.h),
      ),
    );
  }
}
