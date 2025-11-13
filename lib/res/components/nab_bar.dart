// lib/res/components/nab_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // ADD
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
  State<SmoothNavigationWrapper> createState() =>
      _SmoothNavigationWrapperState();
}

class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper> {
  late PageController _pageController;
  late int _currentIndex;
  late ValueNotifier<bool> _isRecordingNotifier;
  late ValueNotifier<bool> _showEventCardNotifier;

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
    _showEventCardNotifier = ValueNotifier<bool>(false);
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
    _showEventCardNotifier.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.lightImpact();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      final speech = context.read<SpeechProvider>();

      if (_isRecordingNotifier.value) {
        // STOP
        speech.stopListening();
        _isRecordingNotifier.value = false;
        _showEventCardNotifier.value = true;
      } else {
        // START
        final started = speech.startListening();
        if (started is Future) {
          started.then((success) {
            if (success) {
              _isRecordingNotifier.value = true;
            }
          });
        } else {
          _isRecordingNotifier.value = true;
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
      _isRecordingNotifier.value = false;
      _showEventCardNotifier.value = false;
    });
    _pageController.jumpToPage(realPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isSinglePage = widget.child != null;

    return Theme(
      data: Theme.of(context)
          .copyWith(scaffoldBackgroundColor: AppColors.white),
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

            // Red overlay while recording
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

            // Event card popup with LIVE TEXT
            ValueListenableBuilder<bool>(
              valueListenable: _showEventCardNotifier,
              builder: (context, showEventCard, child) {
                if (!showEventCard) return const SizedBox.shrink();
                return _buildEventPopup();
              },
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildEventPopup() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => _showEventCardNotifier.value = false,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => _showEventCardNotifier.value = false,
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

                  // LIVE TEXT FROM SPEECH PROVIDER
                  Consumer<SpeechProvider>(
                    builder: (context, speech, child) {
                      final text = speech.text.trim();
                      return SpeackEventCard(
                        eventTitle: "Voice Summary",
                        note: text.isEmpty ? "No speech detected" : text,
                        initialReminder: "At time of event",
                        initialCallMe: false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.2),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : AppColors.green,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : AppColors.green)
                        .withOpacity(0.3),
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
        splashColor: AppColors.green.withOpacity(0.1),
        highlightColor: AppColors.green.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// // lib/res/components/nab_bar.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
//
// import 'package:saytask/repository/notes_service.dart';
// import 'package:saytask/view/home/home_screen.dart';
// import 'package:saytask/view/today/today_screen.dart';
// import 'package:saytask/view/calendar/calendar_screen.dart';
// import 'package:saytask/view/note/notes_screen.dart';
// import 'package:saytask/view/note/create_note_screen.dart';
// import 'package:saytask/view/event/event_details_screen.dart';
// import 'package:saytask/view/note/note_details_screen.dart';
// import 'package:saytask/view/today/task_details_screen.dart';
// import 'package:saytask/view/speak_screen/speak_screen.dart';
// import '../color.dart';
// import 'speak_screen/event_card.dart';
//
// class SmoothNavigationWrapper extends StatefulWidget {
//   final Widget? child;
//   final int initialIndex;
//
//   const SmoothNavigationWrapper({
//     Key? key,
//     this.child,
//     this.initialIndex = 0,
//   }) : super(key: key);
//
//   @override
//   State<SmoothNavigationWrapper> createState() =>
//       _SmoothNavigationWrapperState();
// }
//
// class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper>
//     with TickerProviderStateMixin {
//   late PageController _pageController;
//   late int _currentIndex;
//   bool _isRecording = false;
//   bool _showEventCard = false;
//
//   List<Widget> get _pages => const [
//     HomeScreen(),
//     TodayScreen(),
//     SpeakHomeScreen(),
//     CalendarScreen(),
//     NotesScreen(),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: _currentIndex);
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   void _onPageChanged(int index) {
//     setState(() => _currentIndex = index);
//     HapticFeedback.lightImpact();
//   }
//
//   void _onTabTapped(int index) {
//     if (index == 2) {
//       // Mic button tapped
//       setState(() {
//         if (_isRecording) {
//           _showEventCard = true;
//         } else {
//           _isRecording = true;
//         }
//       });
//       HapticFeedback.mediumImpact();
//       return;
//     }
//
//     // Switch to other tabs
//     setState(() {
//       _currentIndex = index;
//       _isRecording = false;
//       _showEventCard = false;
//     });
//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOutCubic,
//     );
//   }
//
//   void _stopRecording() {
//     setState(() {
//       _isRecording = false;
//       _showEventCard = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isSinglePage = widget.child != null;
//
//     return Theme(
//       data: Theme.of(context).copyWith(scaffoldBackgroundColor: AppColors.white),
//       child: Scaffold(
//         body: Stack(
//           children: [
//             // Main PageView or single page
//             isSinglePage
//                 ? widget.child!
//                 : PageView(
//               controller: _pageController,
//               onPageChanged: _onPageChanged,
//               physics: const BouncingScrollPhysics(),
//               children: _pages,
//             ),
//
//             // Slight overlay when recording
//             if (_isRecording)
//               Positioned.fill(
//                 child: IgnorePointer(
//                   child: Container(color: Colors.red.withOpacity(0.05)),
//                 ),
//               ),
//
//             // Event card popup
//             if (_showEventCard) _buildEventPopup(),
//           ],
//         ),
//         bottomNavigationBar: _buildBottomNav(),
//       ),
//     );
//   }
//
//   Widget _buildEventPopup() {
//     return Positioned.fill(
//       child: GestureDetector(
//         onTap: () => setState(() => _showEventCard = false),
//         child: Container(
//           color: Colors.black.withOpacity(0.5),
//           child: Center(
//             child: Material(
//               color: Colors.transparent,
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//                 constraints: const BoxConstraints(maxWidth: 500),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Align(
//                       alignment: Alignment.topRight,
//                       child: GestureDetector(
//                         onTap: () => setState(() => _showEventCard = false),
//                         child: Container(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           padding: const EdgeInsets.all(8),
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.close, color: Colors.black),
//                         ),
//                       ),
//                     ),
//                     SpeackEventCard(
//                       eventTitle: "Recorded Event",
//                       note: "This is a sample event created from voice recording",
//                       initialReminder: "At time of event",
//                       initialCallMe: false,
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             _stopRecording();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Event saved successfully!'),
//                                 backgroundColor: Colors.green,
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.check, color: Colors.white),
//                           label: const Text('Save'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 32, vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         ElevatedButton.icon(
//                           onPressed: _stopRecording,
//                           icon: const Icon(Icons.stop, color: Colors.white),
//                           label: const Text('Stop'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 32, vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomNav() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, -2))
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
//               _buildNavItem(1, Icons.access_time_rounded,
//                   Icons.access_time_rounded, 'Today'),
//               _buildNavItem(2, Icons.mic, Icons.mic, 'Speak', isMic: true),
//               _buildNavItem(3, Icons.event_note_outlined, Icons.event_note, 'Calendar'),
//               _buildNavItem(4, Icons.edit, Icons.edit, 'Notes'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(
//       int index, IconData icon, IconData activeIcon, String label,
//       {bool isMic = false}) {
//     if (isMic) {
//       return GestureDetector(
//         onTap: () => _onTabTapped(index),
//         child: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: _isRecording ? Colors.red : AppColors.green,
//             boxShadow: [
//               BoxShadow(
//                 color: (_isRecording ? Colors.red : AppColors.green)
//                     .withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Icon(
//             _isRecording ? Icons.stop_rounded : Icons.mic,
//             color: Colors.white,
//             size: 30,
//           ),
//         ),
//       );
//     }
//
//     final bool isSelected = _currentIndex == index;
//
//     return GestureDetector(
//       onTap: () => _onTabTapped(index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(isSelected ? activeIcon : icon,
//               color: isSelected ? AppColors.green : Colors.grey, size: 24),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? AppColors.green : Colors.grey,
//               fontSize: 12,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//               fontFamily: 'Poppins',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// // lib/res/components/nab_bar.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:saytask/repository/notes_service.dart';
// import 'package:saytask/view/calendar/calendar_screen.dart';
// import 'package:saytask/view/event/event_details_screen.dart';
// import 'package:saytask/view/note/create_note_screen.dart';
// import 'package:saytask/view/note/notes_screen.dart';
// import '../../view/home/home_screen.dart';
// import '../../view/speak_screen/speak_screen.dart';
// import '../../view/today/today_screen.dart';
// import '../color.dart';
// import 'speak_screen/event_card.dart';
//
// class SmoothNavigationWrapper extends StatefulWidget {
//   final int initialIndex;
//
//   const SmoothNavigationWrapper({
//     Key? key,
//     this.initialIndex = 0,
//   }) : super(key: key);
//
//   @override
//   State<SmoothNavigationWrapper> createState() => _SmoothNavigationWrapperState();
// }
//
// class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper>
//     with TickerProviderStateMixin {
//   late PageController _pageController;
//   late int _currentIndex;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   // Recording state
//   bool _isRecording = false;
//   bool _showEventCard = false;
//
//   List<Widget> get _pages {
//     return [
//       Builder(
//         builder: (context) => const HomeScreen(),
//       ),
//       Builder(
//         builder: (context) => const TodayScreen(),
//       ),
//       Builder(
//         builder: (context) => const SpeakHomeScreen(),
//       ),
//       Builder(
//         builder: (context) => const CalendarScreen(),
//       ),
//       Builder(
//         builder: (context) => const NotesScreen(),
//       ),
//
//
//     ];
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: _currentIndex);
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _onPageChanged(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//
//     HapticFeedback.lightImpact();
//   }
//
//   void _onTabTapped(int index) {
//     // Handle Speak button (index 2)
//     if (index == 2) {
//       if (_isRecording) {
//         // If already recording, show the event card
//         setState(() {
//           _showEventCard = true;
//         });
//       } else {
//         // Start recording
//         setState(() {
//           _isRecording = true;
//         });
//       }
//       HapticFeedback.mediumImpact();
//       return;
//     }
//
//     // Handle other tabs - allow navigation even during recording
//     if (index < _pages.length) {
//       setState(() {
//         _currentIndex = index;
//       });
//       _pageController.animateToPage(
//         index,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOutCubic,
//       );
//     }
//   }
//
//   void _stopRecording() {
//     setState(() {
//       _isRecording = false;
//       _showEventCard = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final pages = _pages;
//
//     // Debug provider availability
//     try {
//       context.read<NotesProvider>();
//       print('NotesProvider found in SmoothNavigationWrapper');
//     } catch (e) {
//       print('NotesProvider NOT found in SmoothNavigationWrapper: $e');
//     }
//
//     return Theme(
//       data: Theme.of(context).copyWith(
//         scaffoldBackgroundColor: AppColors.white,
//       ),
//       child: Scaffold(
//         body: Stack(
//           children: [
//             // Main content
//             FadeTransition(
//               opacity: _fadeAnimation,
//               child: PageView(
//                 controller: _pageController,
//                 onPageChanged: _onPageChanged,
//                 physics: const BouncingScrollPhysics(),
//                 children: pages,
//               ),
//             ),
//
//             // Recording overlay (slight red tint)
//             if (_isRecording)
//               Positioned.fill(
//                 child: IgnorePointer(
//                   child: Container(
//                     color: Colors.red.withOpacity(0.05),
//                   ),
//                 ),
//               ),
//
//             // Event card popup
//             if (_showEventCard)
//               Positioned.fill(
//                 child: GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _showEventCard = false;
//                     });
//                   },
//                   child: Container(
//                     color: Colors.black.withOpacity(0.5),
//                     child: Center(
//                       child: GestureDetector(
//                         onTap: () {}, // Prevent closing when tapping card
//                         child: Material(
//                           color: Colors.transparent,
//                           child: Container(
//                             margin: const EdgeInsets.symmetric(horizontal: 20),
//                             constraints: const BoxConstraints(maxWidth: 500),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 // Close button
//                                 Align(
//                                   alignment: Alignment.topRight,
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         _showEventCard = false;
//                                       });
//                                     },
//                                     child: Container(
//                                       margin: const EdgeInsets.only(bottom: 8),
//                                       padding: const EdgeInsets.all(8),
//                                       decoration: const BoxDecoration(
//                                         color: Colors.white,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: const Icon(
//                                         Icons.close,
//                                         color: Colors.black,
//                                         size: 24,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 // Event card
//                                 SpeackEventCard(
//                                   eventTitle: "Recorded Event",
//                                   note: "This is a sample event created from voice recording",
//                                   initialReminder: "At time of event",
//                                   initialCallMe: false,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 // Action Buttons Row
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     // Save Button
//                                     ElevatedButton.icon(
//                                       onPressed: () {
//                                         // TODO: Implement save logic
//                                         _stopRecording();
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           const SnackBar(
//                                             content: Text('Event saved successfully!'),
//                                             duration: Duration(seconds: 2),
//                                             backgroundColor: Colors.green,
//                                           ),
//                                         );
//                                       },
//                                       icon: const Icon(Icons.check, color: Colors.white),
//                                       label: const Text(
//                                         'Save',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.green,
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 32,
//                                           vertical: 14,
//                                         ),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(25),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     // Stop Recording Button
//                                     ElevatedButton.icon(
//                                       onPressed: _stopRecording,
//                                       icon: const Icon(Icons.stop, color: Colors.white),
//                                       label: const Text(
//                                         'Stop',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.red,
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 32,
//                                           vertical: 14,
//                                         ),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(25),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         bottomNavigationBar: _buildCustomBottomNav(),
//       ),
//     );
//   }
//
//   Widget _buildCustomBottomNav() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
//               _buildNavItem(1, Icons.access_time_rounded, Icons.access_time_rounded, 'Today'),
//               _buildNavItem(2, Icons.mic, Icons.mic, 'Speak', isAlwaysActive: true),
//               _buildNavItem(3, Icons.event_note_outlined, Icons.event_note, 'Calendar'),
//               _buildNavItem(4, Icons.edit, Icons.edit, 'Notes'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(
//       int index,
//       IconData icon,
//       IconData activeIcon,
//       String label, {
//         bool isAlwaysActive = false,
//       }) {
//     final bool isSelected = _currentIndex == index || (isAlwaysActive && index == 2);
//
//     if (index == 2) {
//       return GestureDetector(
//         onTap: () => _onTabTapped(index),
//         child: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: _isRecording ? Colors.red : AppColors.green,
//             boxShadow: [
//               BoxShadow(
//                 color: (_isRecording ? Colors.red : AppColors.green).withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Icon(
//             _isRecording ? Icons.stop_rounded : Icons.mic,
//             color: Colors.white,
//             size: 30,
//           ),
//         ),
//       );
//     }
//
//     return GestureDetector(
//       onTap: () => _onTabTapped(index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isSelected ? activeIcon : icon,
//             color: isSelected ? AppColors.green : Colors.grey,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? AppColors.green : Colors.grey,
//               fontSize: 12,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//               fontFamily: 'Poppins',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _ComingSoonPage extends StatelessWidget {
//   final String title;
//   final IconData icon;
//
//   const _ComingSoonPage({
//     required this.title,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: AppColors.blueColor.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 size: 64,
//                 color: AppColors.blueColor,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.black,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Coming Soon!',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: AppColors.secondaryTextColor,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//             const SizedBox(height: 32),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: AppColors.blueColor,
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: const Text(
//                 'We\'re working hard to bring you this feature!',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontFamily: 'Poppins',
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
