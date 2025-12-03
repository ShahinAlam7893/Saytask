import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/plan_service.dart';
import 'package:saytask/repository/settings_service.dart';
import 'package:saytask/view/settings/profile_card.dart';
import 'package:saytask/view_model/auth_view_model.dart';
import '../../../res/color.dart';
import '../../res/components/settings_tile.dart';
import '../../res/components/toggle_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool whatsappBot = true;
  bool enableAIChatbot = true;
  bool isSubscriptionExpanded = false;
  int selectedPlan = 0; // 0 = Free, 1 = Premium, 2 = Unlimited

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

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
            // Settings Icon
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 30.h,
                      width: 30.w,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(50.r),
                        border: Border.all(color: AppColors.black, width: 1.0),
                      ),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.black,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 100.w),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ProfileCard(
                name: user?.fullName ?? 'Guest',
                email: user?.email ?? 'example@gmaile.com',
                onTap: () {
                  context.push('/profile_screen');
                },
              ),
              SettingTile(
                title: 'Account Management',
                onTap: () {
                  context.push('/account_management');
                },
              ),
              SettingToggleTile(
                title: 'Notifications',
                value: notifications,
                onChanged: (v) => setState(() => notifications = v),
              ),
              SizedBox(height: 8.h),
              SettingTile(
                title: 'Manage Subscription',
                onTap: () {
                  context.push('/plan_screen');
                },
              ),
              SizedBox(height: 8.h),
              SettingToggleTile(
                title: 'Enable WhatsApp Bot',
                value: whatsappBot,
                onChanged: (v) => setState(() => whatsappBot = v),
              ),
              SizedBox(height: 8.h),
              SettingToggleTile(
                title: 'Enable Chatbot',
                value: settingsViewModel.enableAIChatbot,
                onChanged: (v) {
                  settingsViewModel.setEnableAIChatbot(v);
                },
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: Container(
                  height: 40.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryRed,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Icon(Icons.logout, color: AppColors.red),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      title: Text(
                        'Logout Confirmation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), // Cancel
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onPressed: () {
                            context.pop(context);
                            authVM.logout();
                            context.go('/login');
                          },
                          child: Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
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
}
