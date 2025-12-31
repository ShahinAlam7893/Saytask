// view/screens/terms_and_condition.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/legal_view_model.dart';
import 'package:saytask/res/color.dart';


class TermsAndCondition extends StatelessWidget {
  const TermsAndCondition({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = LegalViewModel();
        vm.loadLegalContent();
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
              height: 24.h,
              width: 24.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.0),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 16.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Text(
            'Terms & Condition',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<LegalViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Text(
                  "Error: ${viewModel.errorMessage}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final paragraphs = viewModel.termsContent
                .split('. ')
                .where((s) => s.trim().isNotEmpty)
                .toList();

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: paragraphs.map((para) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Text(
                              "● $para${para.endsWith('.') ? '' : '.'}",
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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