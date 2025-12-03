import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/view_model/auth_view_model.dart';
import '../../res/color.dart';
import '../../res/components/common_button.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      print("❌ ERROR: One or both fields are empty.");
      TopSnackBar.show(
        context,
        message: "Please fill in all fields",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      print("❌ ERROR: Passwords do NOT match.");
      TopSnackBar.show(
        context,
        message: "Passwords do not match",
        backgroundColor: Colors.red,
      );
      return;
    }
    if (auth.verifiedResetToken == null) {
      print("❌ ERROR: verifiedResetToken is NULL — OTP verification missing.");
      TopSnackBar.show(
        context,
        message: "Unauthorized request. Restart reset process.",
        backgroundColor: Colors.red,
      );
      return;
    }

    final success = await auth.setNewPassword(_newPasswordController.text);

    print("📨 API Response: success = $success");

    if (success) {
      print("✅ PASSWORD UPDATED SUCCESSFULLY!");
      TopSnackBar.show(
        context,
        message: "Password updated successfully",
        backgroundColor: Colors.green,
      );

      print("➡ Redirecting to /success");
      context.push('/success');
    } else {
      print("❌ FAILED TO UPDATE PASSWORD VIA API");
      TopSnackBar.show(
        context,
        message: "Failed to update password",
        backgroundColor: Colors.red,
      );
    }

    print("===============================");
    print("🔐 CREATE NEW PASSWORD END");
    print("===============================\n");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // FIX overflow
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, // KEY FIX
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    Text(
                      'Create new password',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    Text(
                      'Your new password must be unique from those\npreviously used.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 32.h),

                    Text(
                      'New Password',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "********",
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          color: AppColors.secondaryTextColor,
                          letterSpacing: 4,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[600],
                            size: 20.sp,
                          ),
                          onPressed: () {
                            setState(() {
                              _isNewPasswordVisible =
                              !_isNewPasswordVisible;
                            });
                          },
                        ),
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
                          borderSide:
                          BorderSide(color: AppColors.green, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "********",
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          color: AppColors.secondaryTextColor,
                          letterSpacing: 4,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[600],
                            size: 20.sp,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                            });
                          },
                        ),
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
                          borderSide:
                          BorderSide(color: AppColors.green, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    CustomButton(
                      text: 'Reset Password',
                      onPressed: _handleResetPassword,
                      height: 50.h,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
