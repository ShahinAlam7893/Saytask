import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:saytask/res/color.dart';
import '../../res/components/recording_completing_dialog.dart';
import '../speak_screen/speak_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isRecording = false;
  String? _selectedFileName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.single.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File selected: ${result.files.single.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file selected'),
          backgroundColor: Colors.red,
        ),
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
        toolbarHeight: 70.h,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/images/Saytask_logo.svg',
              height: 24.h,
              width: 100.w,
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Colors.black,
                size: 24.sp,
              ),
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔹 Search Bar (with working attach icon)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Write or attach your pen...",
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  onPressed: _pickFile, // ✅ open file picker
                  icon: Icon(
                    Icons.attach_file,
                    color: Colors.grey[600],
                    size: 20.sp,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: AppColors.green!, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 14.h,
                ),
              ),
            ),
          ),

          // 🔹 Main Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRecording) ...[
                    GestureDetector(
                      onTap: () => setState(() => isRecording = true),
                      child: Container(
                        width: 160.w,
                        height: 160.w,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 60.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // "Tap to saytask" Text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                        children: const [
                          TextSpan(text: 'Tap to '),
                          TextSpan(
                            text: 'saytask',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),

                    // Meeting Info Text
                    Text(
                      'Meeting today at 3:11 PM with Zen....',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    SpeakScreen(
                      onStop: () {
                        setState(() => isRecording = false);
                        _showRecordingCompleteDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // 🔹 Floating Chat Button
      floatingActionButton: SizedBox(
        width: 60.w,
        height: 60.h,
        child: FloatingActionButton(
          onPressed: () {
            context.push('/chat');
          },
          backgroundColor: AppColors.green,
          shape: const CircleBorder(),
          elevation: 4,
          child: Icon(
            Icons.chat,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
      ),
    );
  }

  void _showRecordingCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordingCompleteDialog(
        onCancel: () {
          context.pop(context);
        },
        onSave: () {
          context.pop(context);
          // handle save logic here
        },
      ),
    );
  }
}
