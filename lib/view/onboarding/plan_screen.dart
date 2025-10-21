import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/repository/plan_service.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(12.w),
            child: Container(
              height: 24.h,
              width: 24.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 16.sp,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          title: Text(
            '',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<PlanViewModel>(
          builder: (context, viewModel, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  Text(
                    "Choose Your Perfect Plan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "You can cancel anytime.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  /// --- Toggle Switch ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(30.r),
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
                                borderRadius: BorderRadius.circular(25.r),
                                boxShadow: viewModel.isMonthly
                                    ? [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                                    : [],
                              ),
                              child: Text(
                                "Monthly",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
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
                                borderRadius: BorderRadius.circular(25.r),
                                boxShadow: !viewModel.isMonthly
                                    ? [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                                    : [],
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Annual  ",
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "SAVE 22%",
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF00A86B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  /// --- Plan Cards ---
                  _buildPlanCard(
                    title: "Free",
                    titleColor: Colors.black,
                    price: "\$0.00",
                    period: viewModel.isMonthly ? "/Monthly" : "/Annually",
                    description:
                    "14 events & reminders per week\n3 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nNo credit card required",
                    buttonText: "Get Started",
                    isPopular: false,
                    isBestValue: false,
                    color: Colors.white,
                    borderColor: Colors.grey.shade300,
                  ),
                  _buildPlanCard(
                    title: "Premium",
                    titleColor: const Color(0xFF00A86B),
                    price: viewModel.isMonthly ? "\$8.99" : "\$6.99",
                    period: viewModel.isMonthly ? "/Monthly" : "/Annually",
                    description:
                    "56 events & reminders per week\n20 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
                    buttonText: "Choose Plan",
                    isPopular: true,
                    color: const Color(0xFFEFFAF2),
                    borderColor: const Color(0xFF00A86B),
                  ),
                  _buildPlanCard(
                    title: "Unlimited",
                    titleColor: const Color(0xFFFF9800),
                    price: viewModel.isMonthly ? "\$19.99" : "\$14.99",
                    period: viewModel.isMonthly ? "/Monthly" : "/Annually",
                    description:
                    "Unlimited events & reminders\nUnlimited personal notes\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
                    buttonText: "Choose Plan",
                    isPopular: false,
                    isBestValue: true,
                    color: const Color(0xFFFFF9E6),
                    borderColor: const Color(0xFFFFC107),
                  ),

                  SizedBox(height: 20.h),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Use',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigate to Terms page
                              context.go('/terms_and_conditions');
                            },
                        ),
                        const TextSpan(text: '  •  '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigate to Privacy Policy page
                              context.go('/privacy_policy');
                            },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required String buttonText,
    required Color color,
    required Color borderColor,
    required Color titleColor,
    bool isPopular = false,
    bool isBestValue = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 20.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isPopular ? 20.h : 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              price,
                              style: GoogleFonts.inter(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              period,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ...description.split('\n').map(
                      (line) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check,
                          color: titleColor,
                          size: 16,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            line,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBestValue
                          ? const Color(0xFFFFC107)
                          : isPopular
                          ? const Color(0xFF00A86B)
                          : AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// --- MOST POPULAR badge (top center) ---
        if (isPopular)
          Positioned(
            top: -14.h,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "MOST POPULAR",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
