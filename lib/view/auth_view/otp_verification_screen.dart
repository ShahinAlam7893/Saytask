import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/common_button.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/view_model/auth_view_model.dart';

class OtpVerificationScreen extends StatefulWidget {
  // Now we properly receive the reset token from navigation
  final String resetToken;

  const OtpVerificationScreen({
    super.key,
    required this.resetToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int _secondsRemaining = 119;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());

    // Set the token in ViewModel so resend/resendOtp can use it
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    auth.resetEmailToken = widget.resetToken;

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _clearOtpFields() {
    for (var c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
  }

  bool get canResend => _secondsRemaining == 0;

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != otpLength) {
      TopSnackBar.show(
        context,
        message: "Please enter a valid 6-digit OTP",
        backgroundColor: Colors.red,
      );
      return;
    }

    final auth = Provider.of<AuthViewModel>(context, listen: false);

    final success = await auth.verifyResetOtp(
      otp,
      widget.resetToken, // Pass the correct token!
    );

    if (!mounted) return;

    if (success) {
      TopSnackBar.show(
        context,
        message: "OTP Verified Successfully!",
        backgroundColor: Colors.green,
      );
      context.push('/create_new_password');
    } else {
      TopSnackBar.show(
        context,
        message: "Invalid or expired OTP",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _resendCode() async {
    if (!canResend) return;

    final auth = Provider.of<AuthViewModel>(context, listen: false);

    _clearOtpFields();
    setState(() => _secondsRemaining = 119);
    _startTimer();

    final success = await auth.resendOtp(widget.resetToken); // Pass token here too

    if (!mounted) return;

    if (success) {
      TopSnackBar.show(
        context,
        message: "New OTP sent!",
        backgroundColor: Colors.green,
      );
    } else {
      TopSnackBar.show(
        context,
        message: "Failed to resend OTP",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              Text(
                'Enter OTP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'A 6-digit code has been sent to your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 40.h),

              // OTP Fields
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12.w,
                runSpacing: 12.h,
                children: List.generate(otpLength, (index) {
                  return SizedBox(
                    width: 50.w,
                    height: 60.h,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == otpLength - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[50],
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
                          borderSide: BorderSide(color: AppColors.green, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < otpLength - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        } else if (index == otpLength - 1 && value.isNotEmpty) {
                          _verifyOtp(); // Auto-submit on last digit
                        }
                      },
                    ),
                  );
                }),
              ),

              SizedBox(height: 24.h),
              Text(
                'Code expires in: ${_formatTime(_secondsRemaining)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 32.h),

              CustomButton(
                text: 'Verify',
                onPressed: _verifyOtp,
                height: 50.h,
              ),

              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                  GestureDetector(
                    onTap: canResend ? _resendCode : null,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: canResend ? AppColors.green : Colors.grey,
                        decoration: canResend ? TextDecoration.underline : null,
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