import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../view/home/home_screen.dart';
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
      const HomeScreen(), // Default page (index 0)
      // Add other pages as needed
      const TodayScreen(), // Mapped to "Today"
      // const ChatListPage(),      // Mapped to "Speak" (placeholder functionality needed)
      // const AvailabilityPage(),  // Mapped to "Calendar"
      // const SettingsPage(),      // Mapped to "Notes"
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
    if (_currentIndex != index && index < _pages.length) { // Safety check
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      // Optionally navigate using go_router if needed
      // context.go(_getPathForIndex(index));
    }
  }

  // Helper to map index to path (optional, for go_router integration)
  String _getPathForIndex(int index) {
    switch (index) {
      case 0: return '/home';
      case 1: return '/today'; // Define this route if needed
      case 2: return '/speak'; // Define this route if needed
      case 3: return '/calendar'; // Define this route if needed
      case 4: return '/notes'; // Define this route if needed
      default: return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.white, // Override background to white
      ),
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: pages.map((page) =>
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: page,
                )
            ).toList(),
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Set navigation bar background to white
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
              _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Today'),
              _buildNavItem(2, Icons.mic, Icons.mic, 'Speak', isAlwaysActive: true),
              _buildNavItem(3, Icons.event_note_outlined, Icons.event_note, 'Calendar'),
              _buildNavItem(4, Icons.edit_outlined, Icons.edit, 'Notes'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label,
      {bool isAlwaysActive = false}) {
    final isSelected = _currentIndex == index || (isAlwaysActive && index == 2);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (index == 2 ? AppColors.green.withOpacity(0.1) : AppColors.blueColor.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? (index == 2 ? AppColors.green : AppColors.blueColor)
                    : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? (index == 2 ? AppColors.green : AppColors.blueColor)
                    : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
              ),
              child: Text(label),
            ),
          ],
        ),
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
      backgroundColor: Colors.white, // Set background to white
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