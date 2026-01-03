import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/calendar_service.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/repository/speech_provider.dart';
import 'package:saytask/repository/today_task_service.dart';
import 'package:saytask/repository/voice_action_repository.dart';
import 'package:saytask/res/components/top_snackbar.dart';
import 'package:saytask/view/home/home_screen.dart';
import 'package:saytask/view/today/today_screen.dart';
import 'package:saytask/view/calendar/calendar_screen.dart';
import 'package:saytask/view/note/notes_screen.dart';
import '../color.dart';
import 'speak_screen/event_card.dart';

class SmoothNavigationWrapper extends StatefulWidget {
  final Widget? child;
  final int initialIndex;

  const SmoothNavigationWrapper({super.key, this.child, this.initialIndex = 0});

  @override
  State<SmoothNavigationWrapper> createState() => _SmoothNavigationWrapperState();
}

class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper> {
  late PageController _pageController;
  late int _currentIndex;

  List<Widget> get _pages => const [
    HomeScreen(),
    TodayScreen(),
    CalendarScreen(),
    NotesScreen(),
  ];

  final List<String> _routes = ['/home', '/today', '/calendar', '/notes'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
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
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.lightImpact();
  }

  Future<void> _onTabTapped(int index) async {
    if (index == 2) {
      final speech = context.read<SpeechProvider>();

      if (speech.isListening) {
        await speech.stopListening();
      } else {
        final started = await speech.startListening();
        if (!started && mounted) {
          TopSnackBar.show(
            context,
            message: "Could not start recording. Check microphone permission.",
            backgroundColor: Colors.orange[700]!,
          );
        }
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
            isSinglePage
                ? widget.child!
                : PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
                  ),

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
                              SpeackEventCard(
                                onSave: () async {
                                  try {
                                    await VoiceActionRepository().saveVoiceAction(cls);

                                    if (cls.type == 'task') {
                                      context.read<TaskProvider>().loadTasks();
                                    } else if (cls.type == 'event') {
                                      context.read<CalendarProvider>().loadEvents();
                                    } else {
                                      context.read<NotesProvider>().loadNotes();
                                    }

                                    TopSnackBar.show(
                                      context,
                                      message: "${cls.type.toUpperCase()} saved successfully!",
                                      backgroundColor: Colors.green[700]!,
                                      duration: const Duration(seconds: 3),
                                    );
                                  } catch (e) {
                                    TopSnackBar.show(
                                      context,
                                      message: "Failed to save: $e",
                                      backgroundColor: Colors.red[700]!,
                                      duration: const Duration(seconds: 4),
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
          ),
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
      return Consumer<SpeechProvider>(
        builder: (context, speech, child) {
          final bool isRecording = speech.isListening;

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