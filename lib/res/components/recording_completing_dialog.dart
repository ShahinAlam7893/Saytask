import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../repository/recording_service.dart';

class RecordingCompleteDialog extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const RecordingCompleteDialog({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordingDialogProvider(),
      child: Consumer<RecordingDialogProvider>(
        builder: (context, provider, _) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            backgroundColor: const Color(0xFF5D6E63),
            child: Container(
              width: 295.w,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF5D6E63),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      provider.isEditing
                          ? Expanded(
                        child: TextField(
                          controller: provider.titleController,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      )
                          : Text(
                        provider.titleController.text,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: provider.toggleEditing,
                        child: Icon(
                          provider.isEditing ? Icons.check : Icons.edit,
                          color: Colors.white70,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Date
                  provider.isEditing
                      ? TextField(
                    controller: provider.dateController,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                      : Text(
                    provider.dateController.text,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Description
                  provider.isEditing
                      ? TextField(
                    controller: provider.descController,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                      : Text(
                    provider.descController.text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Call Me Option
                  GestureDetector(
                    onTap: provider.toggleCallMe,
                    child: Row(
                      children: [
                        Icon(
                          provider.callMe
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                          provider.callMe ? Colors.greenAccent : Colors.white38,
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        Icon(
                          Icons.call,
                          color:
                          provider.callMe ? Colors.greenAccent : Colors.white54,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Call Me',
                          style: TextStyle(
                            color:
                            provider.callMe ? Colors.greenAccent : Colors.white,
                            fontSize: 15.sp,
                            fontWeight: provider.callMe
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

// Notification Option
                  GestureDetector(
                    onTap: provider.toggleNotification,
                    child: Row(
                      children: [
                        Icon(
                          provider.notification
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: provider.notification
                              ? Colors.greenAccent
                              : Colors.white38,
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        Icon(
                          Icons.notifications,
                          color: provider.notification
                              ? Colors.greenAccent
                              : Colors.white54,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '12:00, 1 day before, +1',
                            style: TextStyle(
                              color: provider.notification
                                  ? Colors.greenAccent
                                  : Colors.white,
                              fontSize: 15.sp,
                              fontWeight: provider.notification
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h,),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (provider.isEditing) {
                              provider.finishEditing();
                            } else {
                              onSave();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                          ),
                          child: Text(
                            provider.isEditing ? 'Done Editing' : 'Done',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
