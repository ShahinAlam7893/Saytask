// lib/view/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saytask/view_model/auth_view_model.dart';

import '../../res/color.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  late final TextEditingController nameController;
  late final TextEditingController genderController;
  late final TextEditingController dobController;
  late final TextEditingController emailController;
  late final TextEditingController countryController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<AuthViewModel>().currentUser;

    nameController = TextEditingController(text: user?.fullName ?? 'Guest');
    emailController = TextEditingController(text: user?.email ?? '');

    genderController = TextEditingController(text: user?.gender ?? '');
    dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    countryController = TextEditingController(text: user?.country ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;

    if (user != null) {
      nameController.text = user.fullName;
      emailController.text = user.email;
      genderController.text = user.gender ?? '';
      dobController.text = user.dateOfBirth ?? '';
      countryController.text = user.country ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    genderController.dispose();
    dobController.dispose();
    emailController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authVM = context.read<AuthViewModel>();
    final currentUser = authVM.currentUser;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      fullName: nameController.text.trim(),
      gender: genderController.text.trim().isEmpty
          ? null
          : genderController.text.trim(),
      dateOfBirth: dobController.text.trim().isEmpty
          ? null
          : dobController.text.trim(),
      country: countryController.text.trim().isEmpty
          ? null
          : countryController.text.trim(),
      // phoneNumber: "01993156181", // Add field later if needed
    );

    final success = await authVM.updateProfile(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully!'
                : 'Failed to update profile. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

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
              onPressed: () => Navigator.pop(context),
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
              isEditing
                  ? (authVM.isUpdatingProfile
                        ? Icons.hourglass_empty
                        : Icons.check)
                  : Icons.edit,
              color: Colors.black,
              size: 20.sp,
            ),
            onPressed: authVM.isUpdatingProfile
                ? null
                : () async {
                    setState(() {
                      isEditing = !isEditing;
                    });

                    if (!isEditing) {
                      // Save was pressed
                      await _saveProfile();
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

              // Profile Fields — Your original UI 100% unchanged
              _buildProfileField('Name', nameController),
              _buildProfileField('Gender', genderController),
              _buildProfileField('Date of Birth', dobController),
              _buildProfileField('Email', emailController),
              // _buildProfileField('Country', countryController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller) {
    bool isGenderField = label == "Gender";
    bool isDobField = label == "Date of Birth";

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

          // ------------------- GENDER DROPDOWN ---------------------
          // ------------------- GENDER DROPDOWN ---------------------
          if (isEditing && isGenderField)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Background color
                borderRadius: BorderRadius.circular(8.r), // Rounded corners
                border: Border.all(color: Colors.black26), // Border color
              ),
              child: DropdownButtonFormField<String>(
                value: controller.text.isEmpty ? null : controller.text,
                items: ["male", "female"]
                    .map(
                      (gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender[0].toUpperCase() +
                              gender.substring(1), // Capitalize
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  border: InputBorder.none, // Remove default underline
                ),
                dropdownColor: Colors.white, // Dropdown menu background
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black87,
                  size: 24.sp,
                ),
                onChanged: (value) {
                  controller.text = value ?? "";
                  setState(() {});
                },
              ),
            )
          // ------------------- DATE OF BIRTH PICKER ---------------------
          else if (isEditing && isDobField)
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(controller.text) ??
                      DateTime(2000, 01, 01),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null) {
                  controller.text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  setState(() {});
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Text(
                  controller.text.isEmpty ? "Select Date" : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? Colors.grey : Colors.black,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            )
          // ------------------- NORMAL FIELD ---------------------
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: isEditing
                  ? TextField(
                      controller: controller,
                      cursorColor: AppColors.black,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.black,
                            width: 2.0,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Text(
                      controller.text.isEmpty ? '-' : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? Colors.grey
                            : Colors.black,
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
