import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saytask/res/color.dart';
import 'dart:io';
import '../../res/components/common_button.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  File? _image;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? selectedGender;

  final List<String> genders = ['Male', 'Female'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _image = File(pickedImage.path));
    }
  }

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

              // Name field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Name",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.black),
                ),
              ),
              SizedBox(height: 5.h),
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter your full name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 10.h),

              // Email field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.black),
                ),
              ),
              SizedBox(height: 5.h),
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 10.h),

              // Gender dropdown
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Gender",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.black),
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGender,
                    hint: Text(
                      "Select gender",
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                    iconEnabledColor: Colors.black,
                    onChanged: (value) => setState(() => selectedGender = value),
                    items: genders
                        .map(
                          (gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              // Password field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.black),
                ),
              ),
              SizedBox(height: 5.h),
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
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 10.h),

              // Confirm Password field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Confirm Password",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.black),
                ),
              ),
              SizedBox(height: 5.h),
              TextField(
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: "Confirm your password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 30.h),

              // Signup button (Reusable)
              CustomButton(
                text: "Sign up",
                onPressed: () {
                 context.go('/login');
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

              // Already have an account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/login');
                    },
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
    );
  }
}
