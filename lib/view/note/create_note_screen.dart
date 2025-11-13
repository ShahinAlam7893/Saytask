import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/speech_provider.dart';     // Speech
import 'package:saytask/repository/voice_record_provider_note.dart'; // Summary only
import 'package:saytask/res/color.dart';
import 'package:saytask/model/note_model.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:go_router/go_router.dart';

class CreateNoteScreen extends StatelessWidget {
  const CreateNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<VoiceRecordProvider>(); // Summary
    final notesProvider = context.read<NotesProvider>();
    final speechProvider = context.watch<SpeechProvider>();     // Live text

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Notes",
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mic Button
            GestureDetector(
              onTap: () async {
                if (speechProvider.isListening) {
                  await speechProvider.stopListening();
                  // No need to copy — speechProvider.text is live
                } else {
                  final started = await speechProvider.startListening();
                  if (!started) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please allow microphone access')),
                    );
                  }
                }
              },
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: speechProvider.isListening
                      ? Colors.redAccent
                      : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  speechProvider.isListening ? Icons.stop : Icons.mic,
                  size: 48.sp,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              speechProvider.isListening
                  ? "Recording..."
                  : "Click to start recording",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 28.h),

            // Note Section – LIVE FROM SPEECH PROVIDER
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Note",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                speechProvider.text.isNotEmpty
                    ? speechProvider.text
                    : "Your recorded note text will appear here...",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Summary Section – FROM VOICE RECORD PROVIDER
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Structured Summary:",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: recordProvider.summary.isNotEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recordProvider.summary
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .map((line) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Text(
                    line,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ))
                    .toList(),
              )
                  : Text(
                "Your summarized key points will appear here...",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // Save Button – USE SPEECH TEXT
            if (speechProvider.text.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newNote = Note(
                      title: "New Note",
                      content: speechProvider.text,
                      createdAt: DateTime.now(),
                    );
                    notesProvider.addNote(newNote);
                    speechProvider.clear();
                    recordProvider.resetRecording(); // Clear summary
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    "Save Note",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}