// lib/view/settings/update_password.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/common_button.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/view_model/auth_view_model.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final viewModel = context.read<AuthViewModel>();

    final success = await viewModel.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (success) {
      TopSnackBar.show(
        context,
        message: "Password changed successfully!",
        backgroundColor: Colors.green,
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Password changed successfully!"),
      //     backgroundColor: Colors.green,
      //   ),
      // );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
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
                  border: Border.all(color: Colors.black, width: 1.0),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 16.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              'Change Password',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Your Password',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Current Password
                    _buildLabel("Current Password"),
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),

                    SizedBox(height: 16.h),

                    // New Password
                    _buildLabel("New Password"),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),

                    // Error Message
                    if (vm.changePasswordError != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        vm.changePasswordError!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14.sp,
                        ),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    // Update Button
                    CustomButton(
                      text: vm.isChangingPassword
                          ? "Updating..."
                          : "Update Password",
                      onPressed: vm.isChangingPassword
                          ? () {}
                          : () {
                              if (_currentPasswordController.text.isEmpty ||
                                  _newPasswordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill both fields"),
                                  ),
                                );
                                return;
                              }
                              _updatePassword();
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.black,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      cursorColor: AppColors.black,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        hintText: '••••••••',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.green, width: 2.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
