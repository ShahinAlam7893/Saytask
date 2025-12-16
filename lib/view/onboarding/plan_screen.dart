import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/model/plan_model.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/repository/plan_service.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/view/onboarding/payment_screen.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = PlanViewModel();
        vm.loadPlans();
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(12.w),
            child: Container(
              height: 20.h,
              width: 20.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.0),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 16.sp),
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
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${viewModel.errorMessage}',
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => viewModel.loadPlans(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            print("📋 Total plans loaded: ${viewModel.plans.length}");
            for (var p in viewModel.plans) {
              print(
                "  - ID: ${p.id}, Name: ${p.name}, Monthly: \$${p.monthlyPrice.toStringAsFixed(2)}, Annual: \$${p.annualPrice.toStringAsFixed(2)}",
              );
            }

            final freePlan = viewModel.plans.firstWhere(
              (p) => p.name.toLowerCase() == 'free',
              orElse: () => viewModel.plans.first,
            );
            final basicPlan = viewModel.plans.firstWhere(
              (p) => p.name.toLowerCase() == 'basic',
              orElse: () => viewModel.plans.length > 1
                  ? viewModel.plans[1]
                  : viewModel.plans.first,
            );
            final premiumPlan = viewModel.plans.firstWhere(
              (p) => p.name.toLowerCase() == 'premium',
              orElse: () => viewModel.plans.length > 2
                  ? viewModel.plans[2]
                  : viewModel.plans.first,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  Text(
                    "You can cancel anytime.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 6.h),

                  /// --- Toggle Switch ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(2.w),
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
                                        ),
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
                                        ),
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

                  SizedBox(height: 6.h),

                  /// --- Plan Cards ---
                  _buildPlanCard(
                    context: context,
                    viewModel: viewModel,
                    plan: freePlan,
                    title: "Free",
                    titleColor: Colors.black,
                    description:
                        "14 events & reminders per week\n3 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nNo credit card required",
                    buttonText: "Get Started",
                    isPopular: false,
                    isBestValue: false,
                    color: Colors.white,
                    borderColor: Colors.grey.shade300,
                  ),
                  _buildPlanCard(
                    context: context,
                    viewModel: viewModel,
                    plan: basicPlan,
                    title: "Premium",
                    titleColor: const Color(0xFF00A86B),
                    description:
                        "56 events & reminders per week\n20 personal notes per week\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
                    buttonText: "Choose Plan",
                    isPopular: true,
                    color: const Color(0xFFEFFAF2),
                    borderColor: const Color(0xFF00A86B),
                  ),
                  _buildPlanCard(
                    context: context,
                    viewModel: viewModel,
                    plan: premiumPlan,
                    title: "Unlimited",
                    titleColor: const Color(0xFFFF9800),
                    description:
                        "Unlimited events & reminders\nUnlimited personal notes\nWhatsapp assistant\nUnlimited notifications\nScheduling conflict detection\nCreate events with text, video, or images\nCancel anytime",
                    buttonText: "Choose Plan",
                    isPopular: false,
                    isBestValue: true,
                    color: const Color(0xFFFFF9E6),
                    borderColor: const Color(0xFFFFC107),
                  ),

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
                              context.push('/terms_and_conditions');
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
                              context.push('/privacy_policy');
                            },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required PlanViewModel viewModel,
    required Plan plan,
    required String title,
    required String description,
    required String buttonText,
    required Color color,
    required Color borderColor,
    required Color titleColor,
    bool isPopular = false,
    bool isBestValue = false,
  }) {
    final price = viewModel.getPrice(plan);
    final priceText = "\$${price.toStringAsFixed(2)}";
    final period = "/Monthly";

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
            padding: EdgeInsets.all(12.w),
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
                              priceText,
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
                SizedBox(height: 10.h),
                ...description
                    .split('\n')
                    .map(
                      (line) => Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check, color: titleColor, size: 14),
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

                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) =>
                            Center(child: CircularProgressIndicator()),
                      );

                      try {
                        print("🔍 Selected Plan ID: ${plan.id}");
                        print("🔍 Selected Plan Name: ${plan.name}");
                        print(
                          "🔍 Billing Interval: ${viewModel.isMonthly ? 'month' : 'year'}",
                        );

                        // Validate plan ID before checkout
                        if (plan.id.isEmpty) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invalid plan selected'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Get checkout URL
                        final checkoutUrl = await viewModel.createCheckout(
                          plan.id,
                        );

                        // Close loading dialog
                        Navigator.of(context).pop();

                        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CheckoutPage(checkoutUrl: checkoutUrl),
                            ),
                          );
                        } else {
                          TopSnackBar.show(
                            context,
                            message: 'Failed to create checkout session',
                            backgroundColor: Colors.red,
                          );
                        }
                      } catch (e) {
                        Navigator.of(context).pop();

                        // Extract the error message from the exception
                        String errorMessage = e.toString();
                        // Remove "Exception: " prefix if it exists
                        if (errorMessage.startsWith('Exception: ')) {
                          errorMessage = errorMessage.substring(
                            'Exception: '.length,
                          );
                        }

                        TopSnackBar.show(
                          context,
                          message: errorMessage,
                          backgroundColor: Colors.red,
                        );
                      }
                    },
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
        if (isPopular)
          Positioned(
            top: -14.h,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
