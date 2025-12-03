import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/view_model/auth_view_model.dart';

import '../../res/color.dart';
import '../../res/components/common_button.dart';

class ForgotPassMailScreen extends StatelessWidget {
  ForgotPassMailScreen({super.key});

  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // 🔥 Fix overflow
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                ), // Responsive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50.h),

                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      'Don\'t worry! It happens. Please enter the email address linked with your account.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),

                    SizedBox(height: 30.h),

                    /// ------------------ EMAIL INPUT ------------------
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: AppColors.inputFieldBorder,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    /// ------------------ BUTTON ------------------
                    CustomButton(
                      text: auth.isLoading ? "Sending..." : "Send Code",
                      backgroundColor: AppColors.green,
                      textColor: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      borderRadius: 12,
                      width: double.infinity,
                      onPressed: () async {
                        String email = _emailController.text.trim();

                        if (email.isEmpty) {
                          TopSnackBar.show(
                            context,
                            message: "Email is required",
                            backgroundColor: Colors.red,
                          );
                          return;
                        }

                        final success = await auth.forgotPassword(email);

                        if (success) {
                          TopSnackBar.show(
                            context,
                            message: "OTP sent to your email",
                            backgroundColor: Colors.green,
                          );

                          context.push('/otp_verification', extra: auth.resetEmailToken);
                        } else {
                          TopSnackBar.show(
                            context,
                            message: "Email not found",
                            backgroundColor: Colors.red,
                          );
                        }
                      },
                    ),

                    Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
