
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/notes_service.dart';
import 'package:saytask/view/calendar/calendar_screen.dart';
import 'package:saytask/view/note/notes_screen.dart';
import '../../view/home/home_screen.dart';
import '../../view/speak_screen/speak_screen.dart';
import '../../view/today/today_screen.dart';
import '../color.dart';

class SmoothNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const SmoothNavigationWrapper({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<SmoothNavigationWrapper> createState() => _SmoothNavigationWrapperState();
}

class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Widget> get _pages {
    return [
      Builder(
        builder: (context) => const HomeScreen(),
      ),
      Builder(
        builder: (context) => const TodayScreen(),
      ),
      Builder(
        builder: (context) => const SpeakHomeScreen(),
      ),
      Builder(
        builder: (context) => const CalendarScreen(),
      ),
      Builder(
        builder: (context) => const NotesScreen(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    HapticFeedback.lightImpact();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    // Debug provider availability
    try {
      context.read<NotesProvider>();
      print('NotesProvider found in SmoothNavigationWrapper');
    } catch (e) {
      print('NotesProvider NOT found in SmoothNavigationWrapper: $e');
    }

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.white,
      ),
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: pages,
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.access_time_rounded, Icons.access_time_rounded, 'Today'),
              _buildNavItem(2, Icons.mic, Icons.mic, 'Speak', isAlwaysActive: true),
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
        bool isAlwaysActive = false,
      }) {
    final bool isSelected = _currentIndex == index || (isAlwaysActive && index == 2);

    if (index == 2) {
      return GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green,
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.mic,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.green : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.blueColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.blueColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.secondaryTextColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.blueColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'We\'re working hard to bring you this feature!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}