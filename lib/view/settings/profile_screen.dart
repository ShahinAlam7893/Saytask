import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/color.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  final TextEditingController nameController = TextEditingController(text: 'Gabriel');
  final TextEditingController genderController = TextEditingController(text: 'Male');
  final TextEditingController dobController = TextEditingController(text: '2/11/2000');
  final TextEditingController emailController = TextEditingController(text: 'gabriel4@gmail.com');
  final TextEditingController countryController = TextEditingController(text: 'Japan');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 20.sp),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.black,
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                // Toggle between edit and view mode
                isEditing = !isEditing;
              });
              if (!isEditing) {
                // Save profile changes (you can integrate backend here)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Name
              Text(
                nameController.text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emailController.text,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
              SizedBox(height: 32.h),
              _buildProfileField('Name', nameController),
              _buildProfileField('Gender', genderController),
              _buildProfileField('Date of Birth', dobController),
              _buildProfileField('Email', emailController),
              _buildProfileField('Country', countryController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            child: isEditing
                ? TextField(
              cursorColor: AppColors.black, // cursor color
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                // Line below TextField when not focused
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                // Line below TextField when focused
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.black, width: 2.0),
                ),
              ),
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            )
                : Text(
              controller.text,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
