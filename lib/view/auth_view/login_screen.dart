import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/res/color.dart';

import '../../res/components/common_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              Text(
                "Login",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 40.h),
              // Email Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.inputFieldBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 20.h),

              // Password Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.inputFieldBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 10.h),

              // Remember Me and Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() => rememberMe = value ?? false);
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                      ),
                      Text(
                        "Remember me",
                        style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // Login Button
              CustomButton(
                text: "Login",
                backgroundColor: AppColors.green,
                textColor: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                borderRadius: 12,
                onPressed: () {
                  context.go('/home');
                },
              ),
              SizedBox(height: 30.h),

              // Divider "Or Login with"
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

              // Google Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onPressed: () {},
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
                  onPressed: () {},
                  icon: SvgPicture.asset('assets/images/ri_apple-line.svg', width: 20.w),
                  label: Text(
                    "Continue with Apple",
                    style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              // Signup Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t have an account? ",
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/signup');
                    },
                    child: Text(
                      "Sign up",
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
    );
  }
}
