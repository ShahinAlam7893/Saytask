import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../res/color.dart';

class SettingToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.black),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            color: AppColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: AppColors.green,
          inactiveTrackColor: AppColors.white,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
