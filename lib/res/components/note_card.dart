import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/note_model.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/res/color.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({super.key, required this.note, this.onTap});

  String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
              () {
            context.read<NoteDetailsViewModel>().setSelectedNote(note);
            context.push('/note_details');
              },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFF4EEEE), width: 1.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              note.original,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              getTimeAgo(note.createdAt),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}