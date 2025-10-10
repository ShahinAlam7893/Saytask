import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/view/settings/profile_card.dart';
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
  bool isSubscriptionExpanded = false;
  int selectedPlan = 0; // 0 = Free, 1 = Premium, 2 = Unlimited

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
                      height: 24.h,
                      width: 24.w,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.black,
                            size: 14.sp,
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
                name: 'John Doe',
                email: 'john.doe@example.com',
                onTap: () {context.push('/profile_screen');},
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
              // Buy Subscription Dropdown
              _buildSubscriptionDropdown(),

              SettingToggleTile(
                title: 'Enable WhatsApp Bot',
                value: whatsappBot,
                onChanged: (v) => setState(() => whatsappBot = v),
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
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.black,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                isSubscriptionExpanded = !isSubscriptionExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Subscription',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isSubscriptionExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 24.sp,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1.h,
                  thickness: 1,
                  color: const Color(0xFFF0F0F0),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      // Free Plan
                      _buildPlanCard(
                        planIndex: 0,
                        title: 'Free Plan',
                        tasks: '14 tasks/week',
                        yearlyPrice: '\$XX.XX/year',
                        monthlyPrice: '\$XX.XX/year',
                        isSelected: selectedPlan == 0,
                        showCheckmark: selectedPlan == 0,
                      ),

                      SizedBox(height: 12.h),

                      // Premium Plan
                      _buildPlanCard(
                        planIndex: 1,
                        title: 'Premium Plan',
                        tasks: '56 tasks/week',
                        yearlyPrice: '\$XX.XX/year',
                        monthlyPrice: '\$XX.XX/year',
                        isSelected: selectedPlan == 1,
                      ),

                      SizedBox(height: 12.h),

                      // Unlimited Plan
                      _buildPlanCard(
                        planIndex: 2,
                        title: 'Unlimited',
                        tasks: 'Unlimited+ tasks/week',
                        yearlyPrice: '\$XX.XX/year',
                        monthlyPrice: '\$XX.XX/year',
                        isSelected: selectedPlan == 2,
                      ),

                      SizedBox(height: 16.h),

                      // Buy Now Button
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle buy action
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Buying ${_getPlanName(selectedPlan)}'),
                                backgroundColor: const Color(0xFF34C759),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Buy Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: isSubscriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  String _getPlanName(int index) {
    switch (index) {
      case 0:
        return 'Free Plan';
      case 1:
        return 'Premium Plan';
      case 2:
        return 'Unlimited Plan';
      default:
        return 'Plan';
    }
  }

  Widget _buildPlanCard({
    required int planIndex,
    required String title,
    required String tasks,
    required String yearlyPrice,
    required String monthlyPrice,
    required bool isSelected,
    bool showCheckmark = false,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = planIndex;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF34C759) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button or checkmark
            Container(
              width: 20.w,
              height: 20.w,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showCheckmark
                    ? const Color(0xFF34C759)
                    : Colors.transparent,
                border: Border.all(
                  color: showCheckmark
                      ? const Color(0xFF34C759)
                      : const Color(0xFFCCCCCC),
                  width: showCheckmark ? 0 : 2,
                ),
              ),
              child: showCheckmark
                  ? Icon(
                Icons.check,
                size: 14.sp,
                color: Colors.white,
              )
                  : isSelected
                  ? Center(
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34C759),
                  ),
                ),
              )
                  : null,
            ),

            SizedBox(width: 12.w),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tasks,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        yearlyPrice,
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        monthlyPrice,
                        style: TextStyle(
                          color: const Color(0xFF999999),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}