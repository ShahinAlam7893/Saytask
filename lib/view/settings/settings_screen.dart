import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/plan_service.dart';
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
              _buildSubscriptionDropdown(context),

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

  Widget _buildSubscriptionDropdown(BuildContext context) {
    final viewModel = context.watch<PlanViewModel>();
    bool isExpanded = isSubscriptionExpanded; // keep your local expand variable

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
                    turns: isExpanded ? 0.5 : 0,
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
                      // Monthly / Yearly toggle (custom container style)
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => viewModel.togglePlanType(true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: viewModel.isMonthly
                                        ? AppColors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    "Monthly",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: viewModel.isMonthly
                                          ? AppColors.black
                                          : AppColors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => viewModel.togglePlanType(false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: !viewModel.isMonthly
                                        ? AppColors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    "Annual Save 20%",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: !viewModel.isMonthly
                                          ? AppColors.black
                                          : AppColors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Dynamic plans (from ViewModel)
                      for (int i = 0; i < viewModel.plans.length; i++) ...[
                        _buildPlanCard(
                          context: context,
                          planIndex: i,
                          title: viewModel.plans[i].name,
                          tasks: viewModel.plans[i].description,
                          yearlyPrice: viewModel.plans[i].price,
                          isSelected: viewModel.selectedIndex == i,
                        ),
                        SizedBox(height: 12.h),
                      ],

                      SizedBox(height: 16.h),

                      // Buy Now Button
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: () {
                            final selectedPlan =
                            viewModel.plans[viewModel.selectedIndex];
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Buying ${selectedPlan.name}'),
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
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required int planIndex,
    required String title,
    required String tasks,
    required String yearlyPrice,
    required bool isSelected,
    bool showCheckmark = false,
  }) {
    return GestureDetector(
      onTap: () {
        final viewModel = context.read<PlanViewModel>();
        viewModel.selectPlan(planIndex);
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
            // Radio button / checkmark
            Container(
              width: 20.w,
              height: 20.w,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF34C759) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF34C759)
                      : const Color(0xFFCCCCCC),
                  width: isSelected ? 0 : 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14.sp, color: Colors.white)
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
                  Text(
                    yearlyPrice,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
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