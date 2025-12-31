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

  void initialize(Note note) {
    titleController.text = note.title;
    contentController.text = note.original; 
    structuredSummaryController.text = note.structuredSummary; 
  }

  void enableEditing() {
    _isEditing = true;
    notifyListeners();
  }

  void disableEditing() {
    _isEditing = false;
    notifyListeners();
  }

  Future<void> saveChanges(BuildContext context, Note originalNote) async {
    _isSaving = true;
    notifyListeners();

    try {
      // Parse bullet points back into List<String>
      final List<String> points = structuredSummaryController.text
          .split('\n')
          .map((line) => line.replaceFirst(RegExp(r'^•\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final updatedNote = originalNote.copyWith(
        title: titleController.text.trim().isEmpty ? "Untitled Note" : titleController.text.trim(),
        original: contentController.text.trim(),
        summarized: Summarized(
          summary: "", // your backend ignores this or fills it later
          points: points,
        ),
      );

      // Update in backend + local list
      await context.read<NotesProvider>().updateNote(updatedNote);

      // Update selected note in details VM
      context.read<NoteDetailsViewModel>().setSelectedNote(updatedNote);

      _isEditing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note saved"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red),
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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
  const NoteDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final noteDetailsVM = context.watch<NoteDetailsViewModel>();
    final note = noteDetailsVM.selectedNote;

    // Safety: if no note, go back
    if (note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider(
      create: (_) {
        final vm = EditNoteViewModel();
        vm.initialize(note);
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
                    icon: Icon(Icons.settings_outlined, color: Colors.black, size: 24.sp),
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
                      icon: Icon(Icons.arrow_back_ios_new_outlined, size: 20.sp, color: Colors.black),
                      onPressed: () => context.pop(),
                    ),

                    // Title - Editable
                    if (editVM.isEditing)
                      TextField(
                        controller: editVM.titleController,
                        style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: "Enter title..."),
                      )
                    else
                      Text(
                        note.title,
                        style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                      ),

                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.red, size: 24.sp),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => const ConfirmDialog(
                                title: "Delete Note",
                                message: "Are you sure you want to delete this note?",
                                confirmText: "Delete",
                                cancelText: "Cancel",
                              ),
                            );

                            if (confirmed == true && context.mounted) {
                              await context.read<NotesProvider>().deleteNote(note.id);
                              context.read<NoteDetailsViewModel>().clearSelectedNote();
                              context.pop();
                            }
                          },
                        ),
                      ],
                    ),

                    Text(
                      "Created ${_timeAgo(note.createdAt)}",
                      style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 20.h),

                    // Structured Summary Section
                    Text("Structured Summary:", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600)),
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
                                hintText: "• Point one\n• Point two...",
                              ),
                            )
                          : (note.structuredSummary.trim().isEmpty
                              ? Text("No summary points yet.", style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: note.structuredSummary
                                      .split('\n')
                                      .where((l) => l.trim().isNotEmpty)
                                      .map((line) => Padding(
                                            padding: EdgeInsets.only(bottom: 6.h),
                                            child: Text(line, style: GoogleFonts.inter(fontSize: 14.sp)),
                                          ))
                                      .toList(),
                                )),
                    ),
                    SizedBox(height: 20.h),

                    // Original Note (Collapsible)
                    ExpansionTile(
                      title: Text("Original note", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600)),
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
                                  style: GoogleFonts.inter(fontSize: 14.sp),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                )
                              : Text(
                                  note.original,
                                  style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Edit / Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: editVM.isSaving
                            ? null
                            : () async {
                                if (editVM.isEditing) {
                                  await editVM.saveChanges(context, note);
                                } else {
                                  editVM.enableEditing();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: editVM.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                editVM.isEditing ? "Save Changes" : "Edit Note",
                                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                    SizedBox(height: 40.h),
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
    if (diff.inDays >= 1) return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    if (diff.inHours >= 1) return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
    if (diff.inMinutes >= 1) return "${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago";
    return "Just now";
  }
}