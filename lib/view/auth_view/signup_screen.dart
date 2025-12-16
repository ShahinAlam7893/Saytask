// lib/view/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/top_snackbar.dart';

import '../../res/components/common_button.dart';
import '../../view_model/auth_view_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  // String? selectedGender;

  // final List<String> genders = ['Male', 'Female'];

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleSignup(BuildContext context) async {
  if (!formKey.currentState!.validate()) return;

  if (passwordController.text != confirmPasswordController.text) {
    TopSnackBar.show(
      context,
      message: "Passwords do not match.",
      backgroundColor: Colors.red,
    );
    return;
  }

  final authVM = context.read<AuthViewModel>();

  final success = await authVM.register(
    fullName: nameController.text.trim(),
    email: emailController.text.trim(),
    password: passwordController.text.trim(),
  );

  if (success) {
    TopSnackBar.show(
      context,
      message: "Registered successfully! Please login.",
      backgroundColor: Colors.green,
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      context.go('/login');
    });
  } else {
    TopSnackBar.show(
      context,
      message: "Registration failed! Try again.",
      backgroundColor: Colors.red,
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Sign up",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 30.h),

                // Name
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Name",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black),
                  ),
                ),
                SizedBox(height: 5.h),
                TextFormField(
                  controller: nameController,
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                  decoration: InputDecoration(
                    hintText: "Enter your full name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 10.h),

                // Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black),
                  ),
                ),
                SizedBox(height: 5.h),
                TextFormField(
                  controller: emailController,
                  validator: (v) => v != null && v.contains("@") ? null : "Enter valid email",
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 10.h),

                // Gender Dropdown (UI unchanged; not sent to backend)
                // Align(
                //   alignment: Alignment.centerLeft,
                //   child: Text(
                //     "Gender",
                //     style: TextStyle(
                //         fontFamily: 'Inter',
                //         fontSize: 14.sp,
                //         fontWeight: FontWeight.w500,
                //         color: AppColors.black),
                //   ),
                // ),
                // SizedBox(height: 5.h),
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 16.w),
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(8.r),
                //     border: Border.all(color: Colors.grey),
                //   ),
                //   child: DropdownButtonHideUnderline(
                //     child: DropdownButton<String>(
                //       value: selectedGender,
                //       hint: Text(
                //         "Select gender",
                //         style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                //       ),
                //       isExpanded: true,
                //       dropdownColor: Colors.white,
                //       style: TextStyle(
                //           color: Colors.black,
                //           fontSize: 14.sp,
                //           fontFamily: 'Poppins'),
                //       iconEnabledColor: Colors.black,
                //       onChanged: (value) {
                //         setState(() => selectedGender = value);
                //       },
                //       items: genders
                //           .map(
                //             (gender) => DropdownMenuItem(
                //               value: gender,
                //               child: Text(
                //                 gender,
                //                 style: TextStyle(
                //                     color: Colors.black, fontSize: 14.sp),
                //               ),
                //             ),
                //           )
                //           .toList(),
                //     ),
                //   ),
                // ),
                // SizedBox(height: 10.h),

                // Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black),
                  ),
                ),
                SizedBox(height: 5.h),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  validator: (v) => v != null && v.length >= 6 ? null : "Password too short",
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 10.h),

                // Confirm Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Confirm Password",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black),
                  ),
                ),
                SizedBox(height: 5.h),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  validator: (v) => v!.isNotEmpty ? null : "Confirm password",
                  decoration: InputDecoration(
                    hintText: "Confirm your password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                          () => obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 30.h),

                // SIGN UP button
                authVM.isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: "Sign up",
                        onPressed: () => handleSignup(context),
                      ),

                SizedBox(height: 30.h),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        "Or Login with",
                        style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),

                SizedBox(height: 20.h),

                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: () async{
                   
                      await authVM.signInWithGoogle();
                    },
                    icon: SvgPicture.asset('assets/images/google_ic.svg', width: 20.w),
                    label: Text(
                      "Continue with Google",
                      style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Apple Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: () async{
                      await authVM.appleLogin();
                    },
                    icon: SvgPicture.asset('assets/images/ri_apple-line.svg', width: 20.w),
                    label: Text(
                      "Continue with Apple",
                      style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
