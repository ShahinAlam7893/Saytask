// lib/res/components/nab_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/view/home/home_screen.dart';
import 'package:saytask/view/today/today_screen.dart';
import 'package:saytask/view/calendar/calendar_screen.dart';
import 'package:saytask/view/note/notes_screen.dart';
import '../color.dart';
import 'speak_screen/event_card.dart';

class SmoothNavigationWrapper extends StatefulWidget {
  final Widget? child;
  final int initialIndex;

  const SmoothNavigationWrapper({
    Key? key,
    this.child,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<SmoothNavigationWrapper> createState() => _SmoothNavigationWrapperState();
}

class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper> {
  late PageController _pageController;
  late int _currentIndex;
  late ValueNotifier<bool> _isRecordingNotifier;

  List<Widget> get _pages => const [
        HomeScreen(),
        TodayScreen(),
        CalendarScreen(),
        NotesScreen(),
      ];

  final List<String> _routes = [
    '/home',
    '/today',
    '/calendar',
    '/notes',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _isRecordingNotifier = ValueNotifier<bool>(false);
  }

  @override
  void didUpdateWidget(SmoothNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _isRecordingNotifier.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.lightImpact();
  }

  Future<void> _onTabTapped(int index) async {
    if (index == 2) {
      final speech = context.read<SpeechProvider>();

      if (_isRecordingNotifier.value) {
        // STOP RECORDING → AI will classify automatically
        await speech.stopListening();
        _isRecordingNotifier.value = false;
      } else {
        // START RECORDING
        final started = await speech.startListening();
        _isRecordingNotifier.value = started;
      }
      HapticFeedback.mediumImpact();
      return;
    }

    final int realPageIndex = index < 2 ? index : index - 1;

    if (widget.child != null) {
      context.go(_routes[realPageIndex]);
      return;
    }

    setState(() {
      _currentIndex = realPageIndex;
      _isRecordingNotifier.value = false;
    });
    _pageController.jumpToPage(realPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isSinglePage = widget.child != null;

    return Theme(
      data: Theme.of(context).copyWith(scaffoldBackgroundColor: AppColors.white),
      child: Scaffold(
        body: Stack(
          children: [
            // Main Pages
            isSinglePage
                ? widget.child!
                : PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
                  ),

            // Recording Overlay
            ValueListenableBuilder<bool>(
              valueListenable: _isRecordingNotifier,
              builder: (context, isRecording, child) {
                if (!isRecording) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: Colors.red.withOpacity(0.05)),
                  ),
                );
              },
            ),

            // SMART VOICE CARD — FULLY POWERED BY AI
            Consumer<SpeechProvider>(
              builder: (context, speech, child) {
                if (!speech.shouldShowCard || speech.lastClassification == null) {
                  return const SizedBox.shrink();
                }

                final cls = speech.lastClassification!;

                return Positioned.fill(
                  child: GestureDetector(
                    onTap: () => speech.resetCardState(),
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Close Button
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => speech.resetCardState(),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.black),
                                  ),
                                ),
                              ),

                              // THE CARD — NOW SMART
                              SpeackEventCard(
                                eventTitle: cls.type == 'note'
                                    ? 'New Note'
                                    : (cls.title.isEmpty ? 'New Item' : cls.title),
                                note: cls.description ?? cls.rawText,
                                initialReminder: cls.type == 'note' ? "None" : (cls.reminder),
                                initialCallMe: cls.type == 'note' ? false : cls.callMe,
                                onSave: () async {
                                  try {
                                    final String message;
                                    if (cls.type == 'note') {
                                      message = "Note saved!";
                                    } else if (cls.type == 'event') {
                                      message = "Event: ${cls.title} saved!";
                                    } else {
                                      message = "Task: ${cls.title} saved!";
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Failed to save"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    speech.resetCardState();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.access_time_rounded, Icons.access_time_rounded, 'Today'),
              _buildNavItem(2, Icons.mic, Icons.mic, 'Speak', isMic: true),
              _buildNavItem(3, Icons.event_note_outlined, Icons.event_note, 'Calendar'),
              _buildNavItem(4, Icons.edit, Icons.edit, 'Notes'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool isMic = false,
  }) {
    if (isMic) {
      return ValueListenableBuilder<bool>(
        valueListenable: _isRecordingNotifier,
        builder: (context, isRecording, child) {
          return InkWell(
            onTap: () => _onTabTapped(index),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : AppColors.green,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : AppColors.green).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      );
    }

    final int realPageIndex = index < 2 ? index : index - 1;
    final bool isSelected = _currentIndex == realPageIndex;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.green : Colors.grey,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.green : Colors.grey,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}