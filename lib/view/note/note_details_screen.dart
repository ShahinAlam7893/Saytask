import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/model/note_model.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/res/color.dart';
import 'package:saytask/res/components/confirmation_dialog.dart';

class EditNoteViewModel with ChangeNotifier {
  bool _isEditing = false;
  bool _isSaving = false;

  bool get isEditing => _isEditing;
  bool get isSaving => _isSaving;

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final structuredSummaryController = TextEditingController();

  // 🟢 NEW: Initialize the controller with the note data
  void initialize(Note note) {
    titleController.text = note.title;
    contentController.text = note.content;
    structuredSummaryController.text =
        note.structuredSummary ?? "• Try blue and orange for dashboard color\n• Talk with dev about login page bug\n• Change the heading font";
  }

  void enableEditing(Note note) {
    _isEditing = true;
    titleController.text = note.title;
    contentController.text = note.content;
    structuredSummaryController.text =
        note.structuredSummary ?? "• Try blue and orange for dashboard color\n• Talk with dev about login page bug\n• Change the heading font";
    notifyListeners();
  }

  void disableEditing() {
    _isEditing = false;
    notifyListeners();
  }

  Future<void> saveChanges(BuildContext context, Note note) async {
    _isSaving = true;
    notifyListeners();

    final updatedNote = Note(
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      createdAt: note.createdAt,
      structuredSummary: structuredSummaryController.text.trim(),
    );

    context.read<NotesProvider>().updateNote(updatedNote);
    context.read<NoteDetailsViewModel>().setSelectedNote(updatedNote);

    _isSaving = false;
    _isEditing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    structuredSummaryController.dispose();
    super.dispose();
  }
}

class NoteDetailsScreen extends StatelessWidget {
  const NoteDetailsScreen({super.key, required Note note});

  @override
  Widget build(BuildContext context) {
    final noteDetailsVM = context.watch<NoteDetailsViewModel>();
    final note = noteDetailsVM.selectedNote;

    if (note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider(
      create: (_) {
        final vm = EditNoteViewModel();
        vm.initialize(note); // 🟢 Initialize with note data immediately
        return vm;
      },
      child: Consumer<EditNoteViewModel>(
        builder: (context, editVM, _) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
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
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_outlined,
                          size: 20.sp, color: Colors.black),
                      onPressed: context.pop,
                    ),
                    editVM.isEditing
                        ? TextField(
                      controller: editVM.titleController,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter title...",
                      ),
                    )
                        : const SizedBox.shrink(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        editVM.isEditing
                            ? const SizedBox.shrink()
                            : Text(
                          note.title,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.red,
                            size: 24.sp,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => const ConfirmDialog(
                                title: "Delete Note",
                                message:
                                "Are you sure you want to delete this note?",
                                confirmText: "Delete",
                                cancelText: "Cancel",
                              ),
                            );
                            if (confirm == true) {
                              noteDetailsVM.deleteSelectedNote(context);
                              if (context.mounted) context.pop();
                            }
                          },
                        ),
                      ],
                    ),
                    Text(
                      "Created ${_timeAgo(note.createdAt)}",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 🟢 Structured Summary (now visible and editable)
                    Text(
                      "Structured Summary:",
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: editVM.isEditing
                          ? TextField(
                        controller: editVM.structuredSummaryController,
                        maxLines: null,
                        style: GoogleFonts.inter(fontSize: 14.sp),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Write structured summary here...",
                        ),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: editVM
                            .structuredSummaryController.text
                            .split('\n')
                            .where((line) => line.trim().isNotEmpty) // Filter empty lines
                            .map((line) => Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            line,
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400),
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    ExpansionTile(
                      title: Text(
                        "Original note",
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: editVM.isEditing
                              ? TextField(
                            controller: editVM.contentController,
                            maxLines: null,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Write your note here...",
                            ),
                          )
                              : Text(
                            note.content,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Edit / Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: editVM.isSaving
                            ? null
                            : () {
                          if (editVM.isEditing) {
                            editVM.saveChanges(context, note);
                          } else {
                            editVM.enableEditing(note);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: editVM.isSaving
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          editVM.isEditing ? "Save Note" : "Edit Note",
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) {
      return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    } else if (diff.inHours >= 1) {
      return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }
}
